resource "aws_api_gateway_vpc_link" "main" {
  name        = "test_gateway_vpclink"
  description = "Test Gateway VPC Link. Managed by Terraform."
  target_arns = ["arn:aws:elasticloadbalancing:us-east-1:378188326309:loadbalancer/net/a33901b2ca99b42ab9f8460e32502469/3b347191897e0e7e"]
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "test_gateway"
  description = "Test Gateway used for EKS. Managed by Terraform."
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy"           = true
    "method.request.header.Authorization" = true
  }
}

resource "aws_iam_role" "api_gateway_role" {
  name = "api_gateway_load_balancer_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lb_access_policy" {
  name        = "lb_access_policy"
  description = "Policy to allow API Gateway access to Load Balancer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "elasticloadbalancing:Invoke"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lb_access_attachment" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.lb_access_policy.arn
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = "ANY"

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://a33901b2ca99b42ab9f8460e32502469-3b347191897e0e7e.elb.us-east-1.amazonaws.com/{proxy}"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  request_parameters = {
    "integration.request.path.proxy"           = "method.request.path.proxy"
    "integration.request.header.Accept"        = "'application/json'"
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.main.id

  credentials = aws_iam_role.api_gateway_role.arn
}
