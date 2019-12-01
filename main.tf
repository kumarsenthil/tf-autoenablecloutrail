provider "aws" {
  region = var.region
  version = "~> 2.7"
}

# Archive the code or project that we want to run
data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "index.js"
    output_path   = "lambda_function.zip"
}

# Create the function
resource "aws_lambda_function" "cloudtrail_lambda" {
  count = "${var.autoenable_cloudtrail ? 1 : 0}"
  filename         = "lambda_function.zip"
  function_name    = "cloudtrail_lambda"
  role             = "${aws_iam_role.iam_for_lambda_tf.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs8.10"
}

# Necessary permissions to create/run the function 
resource "aws_iam_role" "iam_for_lambda_tf" {
  count = "${var.autoenable_cloudtrail ? 1 : 0}"
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
