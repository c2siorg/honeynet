# Filebeat Configuration Template
resource "aws_instance" "honeypot" {
  count = var.honeypot_count
  
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.honeypot_sg.id]
  associate_public_ip_address = true
  user_data      = templatefile("${path.module}/user_data.sh")

  tags = merge(var.tags, {
    Name = "honeynet-honeypot-${count.index}"
  })
}

# Security Group for Honeypot with Filebeat
resource "aws_security_group" "honeypot_sg" {
  name        = "honeypot-with-filebeat-sg"
  description = "Security group for honeypot with Filebeat"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Cowrie SSH honeypot"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Cowrie Telnet honeypot"
    from_port   = 2223
    to_port     = 2223
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "honeypot-with-filebeat-sg"
  }
}
