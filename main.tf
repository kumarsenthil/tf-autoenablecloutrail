provider "aws" {
  region = var.region
  version = "~> 2.7"
}

# Archive the code or project that we want to run
data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "${path.module}/index.py"
    output_path   = "${path.module}/lambda_function.zip"
}

# Create the function
resource "aws_lambda_function" "cloudtrail_lambda" {
  #count = "${var.autoenable_cloudtrail ? 1 : 0}"
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "cloudtrail_lambda"
  role             = "${aws_iam_role.iam_for_lambda_tf.arn}"
  handler          = "index.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "python3.8"
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

#Cloudwatch log permission policy
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
    },
    {
        "Action": [
            "cloudtrail:*"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
}

#Policy attachment to the role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.iam_for_lambda_tf.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_cloudwatch_event_rule" "enable_cloudtrail_rule" {
    name = "enable_cloudtrail_rule"
    description = "Enable cloudtrail if it is disabled"
    event_pattern = <<PATTERN
{
  "source": [
    "aws.cloudtrail"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "cloudtrail.amazonaws.com"
    ],
    "eventName": [
      "StopLogging"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "enable_cloudtrail_target" {
    rule = "${aws_cloudwatch_event_rule.enable_cloudtrail_rule.name}"
    target_id = "${aws_lambda_function.cloudtrail_lambda.function_name}"
    arn = "${aws_lambda_function.cloudtrail_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.cloudtrail_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.enable_cloudtrail_rule.arn}"
}
