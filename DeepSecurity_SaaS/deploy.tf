data "template_file" "juno-ssm-deploy" {
  template = file("${path.module}/dsm_deploy_unified.json")
}

resource "aws_ssm_document" "juno-ssm-deploy" {
  name            = "juno_dsa_deploy"
  document_type   = "Command"
  document_format = "JSON"
  content         = data.template_file.juno-ssm-deploy.rendered
}

resource "aws_ssm_association" "dsa_deploy_frequency" {
  name             = aws_ssm_document.juno-ssm-deploy.name
  association_name = "dsa_deployment_check_association"

  targets {
    key    = "tag:${var.EC2_tag_key}"
    values = ["${var.EC2_tag_value}"]
  }

  parameters = {
    TenantID         = var.DSM_Tenent_ID
    Token            = var.Tenent_Token
    DSActivationURL  = var.DSA_URL
    DSActivationPort = var.DSA_Activation_Port
    DSManagerURL     = var.DSM_URL
    WindowsPolicyID  = var.Default_policyNo_windows
    LinuxPolicyID    = var.Default_policyNo_linux
  }
}

resource "aws_cloudwatch_event_rule" "dsa_deploy" {
  name          = "install-deep-security-agent"
  description   = "Installs deep security agent when instance comes to Running state"
  event_pattern = <<PATTERN
  {
    "source": [
      "aws.ec2"
    ],
    "detail-type": [
      "EC2 Instance State-change Notification"
    ],
    "detail": {
      "state": [
        "running"
      ]
    }
  }
PATTERN

}

resource "aws_cloudwatch_event_target" "lambda_call" {
  arn = "${aws_lambda_function.dsa_tag_function.arn}"
  target_id = "trigger_dsa_tag_lambda"
  rule = "${aws_cloudwatch_event_rule.dsa_deploy.name}"
}

resource "aws_lambda_function" "dsa_tag_function" {
  filename         = "tag-ec2-function.zip"
  function_name    = "tag-dsa-ec2"
  role             = "${aws_iam_role.juno_iam_role.arn}"
  handler          = "lambda_function.handler"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("tag-ec2-function.zip")}"
  runtime          = "python3.6"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.dsa_tag_function.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.dsa_deploy.arn}"
}

resource "aws_iam_role" "juno_iam_role" {
  name = "dsa_deploy_ssm_role"
  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC

}

resource "aws_iam_role_policy" "events_run_task_with_role" {
name   = "dsa_task_with_any_role"
role   = aws_iam_role.juno_iam_role.id
policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "lambda:*",
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
DOC

}