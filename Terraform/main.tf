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

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.staticwebsite.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "policy"
    Statement = [
      {
        Sid       = "GithubActionsPutObject"
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.iam_admin_arn}"
        },
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.staticwebsite.arn}/*"
      },
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
            "Service": "cloudfront.amazonaws.com"
        },
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.staticwebsite.arn}/*"
        Condition = {
            "StringEquals": {
                "AWS:SourceArn" = aws_cloudfront_distribution.webcdn.arn
            }
        }
      }
    ]
  })
}
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.staticwebsite.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.staticwebsite.id

  rule {
    object_ownership = "BucketOwnerPreferred"
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
    domain_name              = aws_s3_bucket.staticwebsite.bucket_domain_name
    origin_path = "/Frontend"
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

  price_class = "PriceClass_100"
  
}
#IAM for Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policydoc" {
  statement {
    effect    = "Allow"
    actions   = [
				"dynamodb:BatchGetItem",
				"dynamodb:GetItem",
				"dynamodb:Query",
				"dynamodb:Scan",
				"dynamodb:BatchWriteItem",
				"dynamodb:PutItem",
				"dynamodb:UpdateItem"
			]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "lambda_policy"
  description = "Assume role policy"
  policy      = data.aws_iam_policy_document.policydoc.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
#LAMBDA FUNCTION
resource "aws_lambda_function" "lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/../Backend/api.zip"
  function_name = "http_request_IP-DB"
  role          = aws_iam_role.role.arn
  handler       = "api.lambda_handler"
  runtime       = "python3.9"
}
resource "aws_lambda_permission" "trigger" {
  statement_id  = "AllowExecutionFromAPI"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
#DYNAMODB
resource "aws_dynamodb_table" "db" {
  name           = "resume_visitors"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key = "visitorcount"

  attribute {
    name = "visitorcount"
    type = "S"
  }
  tags = {
    Name        = "dynamodb-table"
    Environment = "dev"
  }
}
resource "aws_dynamodb_table_item" "tableitem" {
  table_name = aws_dynamodb_table.db.name
  hash_key   = aws_dynamodb_table.db.hash_key

  item = jsonencode({
  "visitorcount": {"S" : "visitor-count"},
  "visitorvalue": {"N" : "0"}
  })

  lifecycle {
    ignore_changes = [
      item
    ]
  }
}

#API GATEWAY
resource "aws_api_gateway_rest_api" "api" {
  name = "ExampleAPIGateway"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{resume+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "methodresponse" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integrationresponse" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.methodresponse.status_code
}
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
}
resource "aws_api_gateway_stage" "stage" {
  stage_name = "apiv1"
  rest_api_id = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

#CLOUDVISION

#SNS