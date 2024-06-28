
terraform {
  backend "s3" {
    bucket                  = "terrafromstatebootlabs"
    dynamodb_table          = "Terraform_state_lock"
    key                     = "terraform-project/terraform.tfstate"
    region                  = "eu-north-1"
    acl                     = "bucket-owner-full-control"
  }
}