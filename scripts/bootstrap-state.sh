#!/usr/bin/env bash
set -euo pipefail

#
# bootstrap-state.sh — Provision AWS resources for Terraform remote state
#
# Creates an S3 bucket with versioning and encryption, and a DynamoDB table
# for state locking. Safe to run multiple times (idempotent).
#
# Usage:
#   ./scripts/bootstrap-state.sh
#   ./scripts/bootstrap-state.sh eu-central-1
#   ./scripts/bootstrap-state.sh --help
#

# --- Color codes ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
print_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Defaults ---
REGION="${AWS_DEFAULT_REGION:-eu-central-1}"

usage() {
  echo "Usage: $0 [region]"
  echo ""
  echo "Provision AWS resources for Terraform remote state:"
  echo "  - S3 bucket: petclinic-terraform-state-<account-id>"
  echo "  - DynamoDB table: petclinic-terraform-locks"
  echo ""
  echo "Arguments:"
  echo "  region    AWS region (default: eu-central-1)"
  echo ""
  echo "Examples:"
  echo "  $0              # Use default region eu-central-1"
  echo "  $0 us-east-1    # Specify a different region"
  echo "  $0 -h           # Show this help message"
  exit 0
}

# --- Parse arguments ---
if [[ $# -gt 1 ]]; then
  print_error "Too many arguments."
  echo "Run '$0 --help' for usage."
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    -h|--help)
      usage
      ;;
    *)
      REGION="$1"
      ;;
  esac
fi

# --- Resolve account ID ---
print_info "Resolving AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
readonly ACCOUNT_ID

BUCKET_NAME="petclinic-terraform-state-${ACCOUNT_ID}"
readonly BUCKET_NAME

TABLE_NAME="petclinic-terraform-locks"
readonly TABLE_NAME

echo ""
echo "============================================"
echo "  Bootstrap Terraform State"
echo "  Region:      ${REGION}"
echo "  Account ID:  ${ACCOUNT_ID}"
echo "  Bucket:      ${BUCKET_NAME}"
echo "  Table:       ${TABLE_NAME}"
echo "============================================"
echo ""

# =============================================================================
# S3 Bucket
# =============================================================================
echo "--- S3 Bucket ---"

# Check if bucket already exists
BUCKET_EXISTS=false
if aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
  BUCKET_EXISTS=true
fi

if [[ "${BUCKET_EXISTS}" == "true" ]]; then
  print_warn "S3 bucket '${BUCKET_NAME}' already exists. Checking configuration..."

  # Check versioning
  VERSIONING_STATUS=$(aws s3api get-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --query 'Status' \
    --output text 2>/dev/null || echo "")

  if [[ "${VERSIONING_STATUS}" == "Enabled" ]]; then
    echo "  Versioning: Enabled"
  else
    print_error "Versioning is not enabled on the bucket. Please fix manually."
    exit 1
  fi

  # Check encryption
  ENCRYPTION_STATUS=$(aws s3api get-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --query 'ServerSideEncryptionConfiguration.Rules[0].ServerSideEncryptionByDefault.SSEAlgorithm' \
    --output text 2>/dev/null || echo "")

  if [[ "${ENCRYPTION_STATUS}" == "AES256" ]]; then
    echo "  Encryption: AES256"
  else
    print_error "Server-side encryption (AES256) is not enabled on the bucket. Please fix manually."
    exit 1
  fi

  # Check public access block
  PUBLIC_ACCESS_BLOCK=$(aws s3api get-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --query 'PublicAccessBlockConfiguration' \
    --output json 2>/dev/null || echo "{}")

  # Parse individual settings directly from JSON
  BLOCK_ACLS=$(echo "${PUBLIC_ACCESS_BLOCK}" | grep -o '"BlockPublicAcls"\s*:\s*true' || true)
  BLOCK_POLICY=$(echo "${PUBLIC_ACCESS_BLOCK}" | grep -o '"BlockPublicPolicy"\s*:\s*true' || true)
  IGNORE_ACLS=$(echo "${PUBLIC_ACCESS_BLOCK}" | grep -o '"IgnorePublicAcls"\s*:\s*true' || true)
  RESTRICT=$(echo "${PUBLIC_ACCESS_BLOCK}" | grep -o '"RestrictPublicBuckets"\s*:\s*true' || true)

  if [[ -n "${BLOCK_ACLS}" && -n "${BLOCK_POLICY}" && -n "${IGNORE_ACLS}" && -n "${RESTRICT}" ]]; then
    echo "  Public access: Blocked"
  else
    print_error "Public access is not fully blocked on the bucket. Please fix manually."
    exit 1
  fi

  print_warn "S3 bucket is already configured correctly. Skipping creation."
else
  print_info "Creating S3 bucket: ${BUCKET_NAME}"

  # Create bucket with LocationConstraint (required for non-us-east-1 regions)
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" > /dev/null
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}" > /dev/null
  fi

  print_info "Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --versioning-configuration Status=Enabled > /dev/null

  print_info "Enabling server-side encryption (AES256)..."
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }' > /dev/null

  print_info "Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }' > /dev/null

  print_info "S3 bucket created successfully."
fi

echo ""

# =============================================================================
# DynamoDB Table
# =============================================================================
echo "--- DynamoDB Table ---"

# Check if table already exists
TABLE_EXISTS=false
TABLE_STATUS=$(aws dynamodb describe-table \
  --table-name "${TABLE_NAME}" \
  --region "${REGION}" \
  --query 'Table.TableStatus' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [[ "${TABLE_STATUS}" != "NOT_FOUND" ]]; then
  TABLE_EXISTS=true
fi

if [[ "${TABLE_EXISTS}" == "true" ]]; then
  print_warn "DynamoDB table '${TABLE_NAME}' already exists. Skipping creation."

  # Verify key schema
  KEY_SCHEMA=$(aws dynamodb describe-table \
    --table-name "${TABLE_NAME}" \
    --region "${REGION}" \
    --query 'Table.KeySchema[0].AttributeName' \
    --output text)

  if [[ "${KEY_SCHEMA}" == "LockID" ]]; then
    echo "  Key schema: LockID (correct)"
  else
    print_error "Table has incorrect key schema. Expected LockID, got '${KEY_SCHEMA}'."
    exit 1
  fi
else
  print_info "Creating DynamoDB table: ${TABLE_NAME}"

  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --region "${REGION}" \
    --attribute-definitions '[{"AttributeName": "LockID", "AttributeType": "S"}]' \
    --key-schema '[{"AttributeName": "LockID", "KeyType": "HASH"}]' \
    --billing-mode PAY_PER_REQUEST > /dev/null

  print_info "DynamoDB table created successfully."
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
print_info "Retrieving resource ARNs..."

BUCKET_ARN="arn:aws:s3:::${BUCKET_NAME}"

TABLE_ARN=$(aws dynamodb describe-table \
  --table-name "${TABLE_NAME}" \
  --region "${REGION}" \
  --query 'Table.TableArn' \
  --output text)

echo ""
echo "============================================"
echo -e "  ${GREEN}Terraform State Bootstrap Complete${NC}"
echo "============================================"
echo ""
echo "  S3 Bucket:"
echo "    Name: ${BUCKET_NAME}"
echo "    ARN:  ${BUCKET_ARN}"
echo ""
echo "  DynamoDB Table:"
echo "    Name: ${TABLE_NAME}"
echo "    ARN:  ${TABLE_ARN}"
echo ""
echo "  Region: ${REGION}"
echo ""
echo "  Next steps:"
echo "    1. Add this backend configuration to your Terraform:"
echo ""
echo "       terraform {"
echo "         backend \"s3\" {"
echo "           bucket         = \"${BUCKET_NAME}\""
echo "           key            = \"<your-state-file>.tfstate\""
echo "           region         = \"${REGION}\""
echo "           encrypt        = true"
echo "           dynamodb_table = \"${TABLE_NAME}\""
echo "         }"
echo "       }"
echo ""
echo "    2. Run: terraform init"
echo "============================================"