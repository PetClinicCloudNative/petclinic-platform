# PETPLAT-3: Dev environment backend
terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-522826274224"
    key            = "petclinic/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
