# S3 bucket for contract document storage
resource "aws_s3_bucket" "contracts" {
  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.project_name}-${var.environment}-${local.service_name}-contracts-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "Contract Documents Storage"
  })
}

# Random suffix for bucket name to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "contracts" {
  bucket = aws_s3_bucket.contracts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "contracts" {
  bucket = aws_s3_bucket.contracts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "contracts" {
  bucket = aws_s3_bucket.contracts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "contracts" {
  bucket = aws_s3_bucket.contracts.id

  rule {
    id     = "contract_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Move to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 7 years (2555 days)
    expiration {
      days = 2555
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 bucket notification for contract events (optional)
resource "aws_s3_bucket_notification" "contracts" {
  bucket = aws_s3_bucket.contracts.id

  # This can be extended to send notifications to SNS/SQS when contracts are uploaded
  depends_on = [aws_s3_bucket.contracts]
}

# IAM policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-${var.environment}-${local.service_name}-s3-access"
  description = "IAM policy for Contract Service S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.contracts.arn,
          "${aws_s3_bucket.contracts.arn}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}
