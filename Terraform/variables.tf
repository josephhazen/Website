variable "region" {
  type = string
  default = "us-east-1"
}

variable "s3_name" {
  type = string
  default = "my-website-bucket12345654321"
}

variable "domain" {
  default = "horizontech.cloud"
}

variable "iam_admin_arn" {
  type = string
  default = "836377050370"
}