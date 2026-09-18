terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us, aws.eu, aws.ap]
    }
  }
}

data "aws_iam_policy_document" "honeypot_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "log_sink_write" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [var.log_sink_bucket_arn]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.log_sink_bucket_arn}/*"]
  }
}

resource "aws_iam_role" "honeypot_forwarder" {
  provider           = aws.us
  name               = "honeynet-honeypot-forwarder-role"
  assume_role_policy = data.aws_iam_policy_document.honeypot_assume_role.json
}

resource "aws_iam_role_policy" "log_sink_write" {
  provider = aws.us
  name     = "honeynet-log-sink-write-policy"
  role     = aws_iam_role.honeypot_forwarder.id
  policy   = data.aws_iam_policy_document.log_sink_write.json
}

resource "aws_iam_instance_profile" "honeypot_forwarder" {
  provider = aws.us
  name     = "honeynet-honeypot-forwarder-profile"
  role     = aws_iam_role.honeypot_forwarder.name
}

resource "aws_key_pair" "honeynet_key_us" {
  provider   = aws.us
  key_name   = "honeynet-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_key_pair" "honeynet_key_eu" {
  provider   = aws.eu
  key_name   = "honeynet-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_key_pair" "honeynet_key_ap" {
  provider   = aws.ap
  key_name   = "honeynet-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "honeynet_sg_us" {
  provider = aws.us
  name     = "honeynet-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "honeynet_sg_eu" {
  provider = aws.eu
  name     = "honeynet-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "honeynet_sg_ap" {
  provider = aws.ap
  name     = "honeynet-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu_us" {
  provider    = aws.us
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_eu" {
  provider    = aws.eu
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_ami" "ubuntu_ap" {
  provider    = aws.ap
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "honeypot_us" {
  provider             = aws.us
  ami                  = data.aws_ami.ubuntu_us.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.honeynet_key_us.key_name
  iam_instance_profile = aws_iam_instance_profile.honeypot_forwarder.name

  vpc_security_group_ids = [aws_security_group.honeynet_sg_us.id]

  tags = {
    Name = "honeynet-us-east"
  }
}

resource "aws_instance" "honeypot_eu" {
  provider             = aws.eu
  ami                  = data.aws_ami.ubuntu_eu.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.honeynet_key_eu.key_name
  iam_instance_profile = aws_iam_instance_profile.honeypot_forwarder.name

  vpc_security_group_ids = [aws_security_group.honeynet_sg_eu.id]

  tags = {
    Name = "honeynet-eu-west"
  }
}

resource "aws_instance" "honeypot_ap" {
  provider             = aws.ap
  ami                  = data.aws_ami.ubuntu_ap.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.honeynet_key_ap.key_name
  iam_instance_profile = aws_iam_instance_profile.honeypot_forwarder.name

  vpc_security_group_ids = [aws_security_group.honeynet_sg_ap.id]

  tags = {
    Name = "honeynet-ap-south"
  }
}

output "honeypots" {
  value = {
    us = {
      ip     = aws_instance.honeypot_us.public_ip
      region = "us-east-1"
      name   = "honeynet-us-east"
    }
    eu = {
      ip     = aws_instance.honeypot_eu.public_ip
      region = "eu-west-1"
      name   = "honeynet-eu-west"
    }
    ap = {
      ip     = aws_instance.honeypot_ap.public_ip
      region = "ap-south-1"
      name   = "honeynet-ap-south"
    }
  }
}
