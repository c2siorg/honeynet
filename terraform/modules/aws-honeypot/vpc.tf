locals {
  name = "${var.name_prefix}-${var.region_label}"
}

resource "aws_vpc" "this" {
  # checkov:skip=CKV2_AWS_12: Default SG is explicitly managed in aws_default_security_group.this; workloads attach aws_security_group.honeypot only.
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name
  }
}

# Lock down the VPC default security group so it is not used for workloads; the honeypot uses aws_security_group.honeypot.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    description = "Allow intra-default-SG only (unused by honeypot workloads)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Default SG egress (honeypot uses non-default SG)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130: Honeypot sensor must receive inbound scans; instances need a public IP in this design.
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.42.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "honeypot" {
  # checkov:skip=CKV_AWS_382: Outbound 0.0.0.0/0 required for package updates, Docker pulls, and image layers on the sensor.
  name        = "${local.name}-sg"
  description = "Honeypot ingress and minimal admin egress"
  vpc_id      = aws_vpc.this.id

  # Cowrie SSH honeypot (container listens on 2222, published on host 2222)
  ingress {
    description = "SSH honeypot listener (Cowrie); intentional global ingress for telemetry"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optional host SSH when a key pair is configured
  dynamic "ingress" {
    for_each = var.key_name != null && var.key_name != "" ? [1] : []
    content {
      description = "Admin SSH to OS when key_name is set; restrict admin_ssh_cidr in tfvars"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.admin_ssh_cidr]
    }
  }

  egress {
    description = "Egress for updates and container registry access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}
