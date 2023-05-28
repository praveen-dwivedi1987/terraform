terraform {
  required_version = ">=0.12.0"
  required_providers {
    aws = ">=3.0.0"
  }
}
provider "aws" {
  profile = "default"
  region  = "us-east-1"
  alias   = "region-master"
}


resource "aws_s3_bucket" "example" {
  bucket = "praveen-tfstate-bucket-00001"
  provider = aws.region-master
  tags = {
    Name        = "My bucket"
    Purpose = "statefile"
  }
}