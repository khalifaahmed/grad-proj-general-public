terraform {
  #configure the state file remote location
  backend "s3" {
    bucket = "grad--proj--bucket"
    key    = "Terraform/grad-proj-terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  # determine the region in which we deploy our infrastructure
  region = var.provider_region
}
