terraform {
  backend "s3" {
    bucket  = "terraform-state-304707804854"
    key     = "cloud-image-processor/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}
