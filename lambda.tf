resource "aws_lambda_function" "hyperflow_lambda_executor" {
  function_name = "hyperflow-lambda-executor"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "montage-ecs"
  s3_key = "lambda/1.0.4/hyperflow-awslambda-executor.zip"

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs6.10"
  memory_size = "512"
  timeout = 28

  role = "${aws_iam_role.lambda_exec.arn}"
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

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

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_cw_access" {
  role = "${aws_iam_role.lambda_exec.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}


resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.hyperflow_lambda_executor.arn}"
  principal = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.lambda_api.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.lambda_api.invoke_url}"
}