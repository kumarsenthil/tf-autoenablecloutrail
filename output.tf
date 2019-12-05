output "lambdaarn" {
  value       = "${aws_lambda_function.cloudtrail_lambda.arn}"
  description = "The ARN of the Lambda"
}

output "iamrolearn" {
  value       = "${aws_iam_role.iam_for_lambda_tf.arn}"
  description = "The ARN of the IAM Role"
}
