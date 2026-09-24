locals {
  interface_endpoint_services = toset([
    "ecr.api",
    "ecr.dkr",
    "kms",
    "logs",
  "secretsmanager",
  "ssm",
  "ssmmessages",
  "ec2messages",
])
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoint_services

  vpc_id              = data.terraform_remote_state.network.outputs.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.terraform_remote_state.network.outputs.private_subnet_ids
  security_group_ids  = [aws_security_group.private_endpoints.id]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.terraform_remote_state.network.outputs.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [data.terraform_remote_state.network.outputs.private_route_table_id]
}
