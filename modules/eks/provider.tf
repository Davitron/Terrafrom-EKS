provider "aws" {
  shared_credentials_file = var.aws_credentials
  region                  = var.region
}
