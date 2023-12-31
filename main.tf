terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

module "badges" {
  source = "./badges"
}

module "belts" {
  source = "./belts"
}
