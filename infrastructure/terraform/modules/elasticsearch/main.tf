# Elasticsearch Module
resource "aws_instance" "elasticsearch" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.elasticsearch_sg.id]
  associate_public_ip_address = false

  tags = merge(var.tags, {
    Name = "honeynet-elasticsearch"
  })
}

# Security Group for Elasticsearch
resource "aws_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  description = "Security group for Elasticsearch cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Elasticsearch HTTP"
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Elasticsearch transport"
    from_port   = 9300
    to_port     = 9300
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
    Name = "elasticsearch-sg"
  }
}
