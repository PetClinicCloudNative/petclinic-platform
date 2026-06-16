# PETPLAT-4: Prod environment backend
terraform {
  backend "s3" {
    bucket         = "petclinic-terraform-state-522826274224"
    key            = "petclinic/prod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "petclinic-terraform-locks"
    encrypt        = true
  }
}
