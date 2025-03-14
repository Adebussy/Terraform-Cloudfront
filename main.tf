resource "aws_s3_bucket" "example" {
  bucket = "my-cf-test-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "app/index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_site_block" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##########################################################
#cloudfront Origin Access Identity 

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for my static site"
}

############################################################
#IAM cloud front distribution#

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.example.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


####CLOUDFRONT DISTRIBUTION#############

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.example.bucket_regional_domain_name
    origin_id   = "s3-static-site-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-static-site-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
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
    cloudfront_default_certificate = true
  }

  # Optional: Logging configuration
  # logging_config {
  #   include_cookies = false
  #   bucket          = "your-log-bucket.s3.amazonaws.com"
  #   prefix          = "cloudfront/"
  # }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.example.bucket
  key          = "index.html"
  source       = "${path.module}/app/index.html"
  acl          = "private" # Managed via OAI so keep objects private
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.example.bucket
  key          = "error.html"
  source       = "${path.module}/app/error.html" # Update the path accordingly
  acl          = "private"
  content_type = "text/html"
}

