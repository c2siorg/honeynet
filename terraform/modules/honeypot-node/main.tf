
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "honeynet-key-${var.region}"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "this" {
  name        = "honeynet-sg-${var.region}"
  description = "Honeypot traffic rules"

  # port 22 is the honeypot — intentionally open
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # real management access on a non-standard port
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = var.management_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "honeypot" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    honeypot_type = var.honeypot_type
  })

  tags = {
    Name    = "honeynet-${var.region}"
    Project = "honeynet"
  }
}
