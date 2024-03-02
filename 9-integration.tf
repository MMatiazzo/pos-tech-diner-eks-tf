resource "aws_security_group" "vpc_link" {
  name   = "vpc-link"
  vpc_id = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_apigatewayv2_vpc_link" "eks" {
  name               = "eks"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids = [
    aws_subnet.private-us-east-1a.id,
    aws_subnet.private-us-east-1b.id
  ]
}

resource "aws_apigatewayv2_integration" "eks" {
  api_id = aws_apigatewayv2_api.main.id

  integration_uri    = "arn:aws:elasticloadbalancing:us-east-1:378188326309:listener/net/a3c71340364864faaaa6a2ab103bbf9d/0bffc6d779a8e84f/418b60d7d2cc5c26"
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.eks.id
}

resource "aws_apigatewayv2_route" "get_root" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.eks.id}"
}

output "hello_base_url" {
  value = "${aws_apigatewayv2_stage.dev.invoke_url}"
}