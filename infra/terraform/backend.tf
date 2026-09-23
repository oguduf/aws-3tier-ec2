terraform {
  backend "s3" {
    bucket       = "omer-aws-3tier-tf.state"
    key          = "environments/dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}