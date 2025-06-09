terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "container-runtime-state-bucket"
    key          = "envs/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.29.0" # Replace with the version you've tested
    }
  }
}