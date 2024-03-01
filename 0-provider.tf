terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "cluster_name" {
  default = "pos-tech-diner-cluster"
}

variable "cluster_version" {
  default = "1.29"
}