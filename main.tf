provider "aws" {
  region = var.region
  version = "~> 2.7"
}

# Archive the code or project that we want to run
data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "${path.module}/index.js"
    output_path   = "${path.module}/lambda_function.zip"
}

# Create the function
resource "aws_lambda_function" "cloudtrail_lambda" {
  #count = "${var.autoenable_cloudtrail ? 1 : 0}"
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "cloudtrail_lambda"
  role             = "${aws_iam_role.iam_for_lambda_tf.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs8.10"
}

# Necessary permissions to create/run the function 
resource "aws_iam_role" "iam_for_lambda_tf" {
  #count = "${var.autoenable_cloudtrail ? 1 : 0}"
  name = "iam_for_lambda_tf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.iam_for_lambda_tf.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}
