# Logstash Module
resource "aws_instance" "logstash" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.logstash_sg.id]
  associate_public_ip_address = false

  tags = merge(var.tags, {
    Name = "honeynet-logstash"
  })
}

# Security Group for Logstash
resource "aws_security_group" "logstash_sg" {
  name        = "logstash-sg"
  description = "Security group for Logstash"
  vpc_id      = var.vpc_id

  ingress {
    description = "Logstash HTTP"
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Logstash Beats input"
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "logstash-sg"
  }
}
