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
  default = "arn:aws:iam::836377050370:user/iamadmindevelopment"
}

variable "api_id" {
  default = "spit6s7fd7"
}

variable "api_resource_id" {
  default = "607jtv"
}
/*
variable "allow_origin" {
  default = "https://horizontech.cloud/"
}
*/
variable "allow_methods" {
  description = "Allow methods"
  type        = list(string)

  default = [
    "OPTIONS",
    "GET",
    "POST",
  ]
}
# var.allow_headers
variable "allow_headers" {
  description = "Allow headers"
  type        = list(string)

  default = [
    "Authorization",
    "Content-Type",
    "X-Amz-Date",
    "X-Amz-Security-Token",
    "X-Api-Key",
  ]
}
# var.allow_origin
variable "allow_origin" {
  description = "Allow origin"
  type        = string
  default     = "*"
}

# var.allow_max_age
variable "allow_max_age" {
  description = "Allow response caching time"
  type        = string
  default     = "7200"
}

# var.allowed_credentials
variable "allow_credentials" {
  description = "Allow credentials"
  default     = false
}