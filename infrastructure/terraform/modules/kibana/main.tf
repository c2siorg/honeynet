# Kibana Module
resource "aws_instance" "kibana" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.kibana_sg.id]
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "honeynet-kibana"
  })
}

# Security Group for Kibana
resource "aws_security_group" "kibana_sg" {
  name        = "kibana-sg"
  description = "Security group for Kibana"
  vpc_id      = var.vpc_id

  ingress {
    description = "Kibana HTTP"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kibana-sg"
  }
}
