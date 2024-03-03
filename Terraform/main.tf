terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  profile = "sso-dev"
}


# Create a VPC
resource "aws_vpc" "myfirstvpc" {
  cidr_block = "10.0.0.0/16"
}

#Create a subnet
resource "aws_subnet" "myfirstsubnet" {
  vpc_id     = aws_vpc.myfirstvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "first"
  }
}
#internet gateway
resource "aws_internet_gateway" "myfirstgateway" {
  vpc_id = aws_vpc.myfirstvpc.id

  tags = {
    Name = "first"
  }
}

#associate route table to subnet
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.myfirstsubnet.id
  route_table_id = aws_route_table.myfirstroutettable.id
}

#ec2 instance security group
resource "aws_security_group" "allow" {
  name        = "allow"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myfirstvpc.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

#network interface
resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.myfirstsubnet.id
  private_ips = ["10.0.1.100"]
  security_groups = [aws_security_group.allow.id]


}


#route table
resource "aws_route_table" "myfirstroutettable" {
  vpc_id = aws_vpc.myfirstvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myfirstgateway.id
  }

  tags = {
    Name = "first"
  }
}


#elastic ip
resource "aws_eip" "firsteip" {
  vpc = true
  network_interface = aws_network_interface.foo.id
  associate_with_private_ip = "10.0.1.100"
  depends_on = [ aws_internet_gateway.myfirstgateway ]
}

#request certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "horizontech.cloud"
  validation_method = "DNS"

  tags = {
    Environment = "static site"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#S3 Bucket and ACL
resource "aws_s3_bucket" "staticwebsite" {
  bucket = var.s3_name
  tags = {
    Name        = "Website"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.staticwebsite.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.control]
}

resource "aws_s3_bucket_ownership_controls" "control" {
  bucket = aws_s3_bucket.staticwebsite.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_website_configuration" "s3config" {
  bucket = aws_s3_bucket.staticwebsite.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.staticwebsite.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowGetObjects"
    Statement = [
      {
        Sid       = "AllowPublic"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.staticwebsite.arn}/**"
      }
    ]
  })
}

#CloudFront
locals {
  s3_origin_id   = "${var.s3_name}-origin"
  s3_domain_name = "${var.s3_name}.s3-website-${var.region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "this" {
  
  enabled = true
  
  origin {
    origin_id                = local.s3_origin_id
    domain_name              = local.s3_domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  default_cache_behavior {
    
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_200"
  
}