# =============================================================================
# Honeynet — Centralized Threat Intelligence Data Pipeline
#
# This module provisions the complete telemetry stack:
#   1. S3 Log Sink        — receives Cowrie/Dionaea logs from all regions
#   2. Lambda Enrichment  — auto-enriches attacker IPs via AbuseIPDB
#   3. Glue Crawler       — auto-discovers log schema
#   4. Athena Workgroup   — enables SQL queries on raw attack data
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Log Sink
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "log_sink" {
  bucket        = "${var.name_prefix}-threat-log-sink-1"
  force_destroy = false

  tags = {
    Project     = "honeynet"
    Purpose     = "threat-log-sink"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "log_sink" {
  bucket = aws_s3_bucket.log_sink.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_sink" {
  bucket = aws_s3_bucket.log_sink.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "log_sink" {
  bucket                  = aws_s3_bucket.log_sink.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle: move old logs to cheaper storage automatically
resource "aws_s3_bucket_lifecycle_configuration" "log_sink" {
  bucket = aws_s3_bucket.log_sink.id

  rule {
    id     = "archive-raw-logs"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# S3 bucket for enriched logs output
resource "aws_s3_bucket" "enriched_logs" {
  bucket        = "${var.name_prefix}-enriched-threat-logs-1"
  force_destroy = false

  tags = {
    Project     = "honeynet"
    Purpose     = "enriched-logs"
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enriched_logs" {
  bucket = aws_s3_bucket.enriched_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "enriched_logs" {
  bucket                  = aws_s3_bucket.enriched_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Athena query results bucket
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.name_prefix}-athena-query-results-1"
  force_destroy = true

  tags = {
    Project   = "honeynet"
    Purpose   = "athena-results"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket                  = aws_s3_bucket.athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Secrets Manager — AbuseIPDB API Key
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "abuseipdb_key" {
  name                    = "${var.name_prefix}/abuseipdb-api-key-2"
  description             = "AbuseIPDB API key for threat intelligence enrichment"
  recovery_window_in_days = 7

  tags = {
    Project   = "honeynet"
    ManagedBy = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "abuseipdb_key" {
  secret_id     = aws_secretsmanager_secret.abuseipdb_key.id
  secret_string = var.abuseipdb_api_key
}

# -----------------------------------------------------------------------------
# IAM Role for Lambda
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_enrichment" {
  name               = "${var.name_prefix}-lambda-enrichment-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project   = "honeynet"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  # Read raw logs from S3 sink
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.log_sink.arn}/*"]
  }

  # Write enriched logs to output bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.enriched_logs.arn}/*"]
  }

  # Read AbuseIPDB key from Secrets Manager
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.abuseipdb_key.arn]
  }

  # CloudWatch Logs for Lambda execution logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda_enrichment" {
  name   = "${var.name_prefix}-lambda-enrichment-policy"
  role   = aws_iam_role.lambda_enrichment.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# -----------------------------------------------------------------------------
# Lambda Function — IP Enrichment
# -----------------------------------------------------------------------------

data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambda/enrichment"
  output_path = "${path.module}/lambda_enrichment.zip"
}

resource "aws_lambda_function" "enrichment" {
  filename         = data.archive_file.lambda_package.output_path
  function_name    = "${var.name_prefix}-ip-enrichment"
  role             = aws_iam_role.lambda_enrichment.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      ENRICHED_BUCKET = aws_s3_bucket.enriched_logs.bucket
      SECRET_NAME     = aws_secretsmanager_secret.abuseipdb_key.name
      AWS_REGION_NAME = var.aws_region
    }
  }

  tags = {
    Project   = "honeynet"
    ManagedBy = "terraform"
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.enrichment.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.log_sink.arn
}

# S3 trigger — fires Lambda on every new log file
resource "aws_s3_bucket_notification" "log_trigger" {
  bucket = aws_s3_bucket.log_sink.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.enrichment.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# -----------------------------------------------------------------------------
# AWS Glue — Schema Discovery
# -----------------------------------------------------------------------------

resource "aws_glue_catalog_database" "honeynet" {
  name        = "${replace(var.name_prefix, "-", "_")}_attacks"
  description = "Honeynet enriched attack log database for Athena queries"
}

resource "aws_iam_role" "glue_crawler" {
  name = "${var.name_prefix}-glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.enriched_logs.arn,
      "${aws_s3_bucket.enriched_logs.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "glue_s3" {
  name   = "${var.name_prefix}-glue-s3-policy"
  role   = aws_iam_role.glue_crawler.id
  policy = data.aws_iam_policy_document.glue_s3_access.json
}

resource "aws_glue_crawler" "enriched_logs" {
  name          = "${var.name_prefix}-attack-log-crawler"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.honeynet.name
  description   = "Crawls enriched Cowrie attack logs and infers schema for Athena"

  s3_target {
    path = "s3://${aws_s3_bucket.enriched_logs.bucket}/enriched/"
  }

  schedule = "cron(0 * * * ? *)" # Run every hour

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = {
    Project   = "honeynet"
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Athena Workgroup
# -----------------------------------------------------------------------------

resource "aws_athena_workgroup" "honeynet" {
  name        = "${var.name_prefix}-attack-analysis"
  description = "Athena workgroup for querying honeynet attack data"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Project   = "honeynet"
    ManagedBy = "terraform"
  }
}
