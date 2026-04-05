provider "aws" {

  region = "us-east-1"

  default_tags {
    tags = {
      Project = "bugAicha"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "bugaicha-state-file"
    key    = "states/terraform.tfstate"
    region = "us-east-1"
  }
}
