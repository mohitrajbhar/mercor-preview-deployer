terraform {
  backend "s3" {
    bucket         = "test-terraform-state-bucket-mohit"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
