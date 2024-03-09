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
  domain_name       = var.domain
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
  bucket = var.domain

  tags = {
    Name        = "Website"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.staticwebsite.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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

#Route53
resource "aws_route53_zone" "primary" {
  name = var.domain
}
resource "aws_route53_record" "domain-a" {
  zone_id = aws_route53_zone.primary.id
  name    = var.domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.webcdn.domain_name
    zone_id                = aws_cloudfront_distribution.webcdn.hosted_zone_id
    evaluate_target_health = false
  }
}



#CloudFront
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "webcdn" {
  aliases = [ var.domain ]
  enabled = true
  default_root_object = "index.html"
  is_ipv6_enabled     = true
  
  origin {
    origin_id                = local.s3_origin_id
    domain_name              = aws_s3_bucket.staticwebsite.bucket_regional_domain_name
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }

  price_class = "PriceClass_200"
  
}