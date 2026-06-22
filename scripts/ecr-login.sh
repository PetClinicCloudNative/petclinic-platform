#!/usr/bin/env bash
set -euo pipefail
#
# ecr-login.sh — Authenticate Docker with AWS ECR private registry
#
# Usage:
#   ./scripts/ecr-login.sh
#   ./scripts/ecr-login.sh --region us-east-1
#

REGION="eu-central-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--region REGION]"
      echo ""
      echo "Authenticate Docker with AWS ECR."
      echo "Default region: eu-central-1"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--region REGION]" >&2
      exit 1
      ;;
  esac
done

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Authenticating Docker to ECR registry: ${REGISTRY}"
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${REGISTRY}"

echo "ECR login successful."
