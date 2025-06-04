data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

locals {
  project_name = "cloud-image-processor"
}

resource "aws_s3_bucket" "images" {
  bucket = "${local.project_name}-s3-${data.aws_caller_identity.current.account_id}"

  force_destroy = true
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.project_name}_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${local.project_name}_lambda_policy_attach"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "thumbnail" {
  function_name = "${local.project_name}_lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "resizer.lambda_handler"
  runtime       = var.runtime
  timeout       = 10

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET = aws_s3_bucket.images.bucket
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_bucket_notification" "notify_lambda" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnail.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}
