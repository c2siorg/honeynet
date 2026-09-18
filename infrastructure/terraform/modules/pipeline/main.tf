# Automated Pipeline Infrastructure
resource "aws_instance" "pipeline_controller" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.pipeline_sg.id]
  associate_public_ip_address = true
  user_data      = templatefile("${path.module}/user_data.sh", {
    elasticsearch_endpoint = var.elasticsearch_endpoint
    kafka_endpoint        = var.kafka_endpoint
    redis_endpoint       = var.redis_endpoint
  })

  tags = merge(var.tags, {
    Name = "honeynet-pipeline-controller"
  })
}

# Security Group for Pipeline Controller
resource "aws_security_group" "pipeline_sg" {
  name        = "pipeline-sg"
  description = "Security group for automated pipeline controller"
  vpc_id      = var.vpc_id

  ingress {
    description = "Pipeline management API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_api_cidr]
  }

  ingress {
    description = "Kafka communication"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Redis communication"
    from_port   = 6379
    to_port     = 6379
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
    Name = "pipeline-sg"
  }
}

# Low-Interaction Honeypot Fleet
resource "aws_instance" "low_interaction_honeypots" {
  count         = var.low_interaction_count
  ami           = var.ami_id
  instance_type  = var.low_interaction_instance_type
  key_name       = var.key_name
  subnet_id      = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.low_interaction_sg.id]
  associate_public_ip_address = true
  user_data      = templatefile("${path.module}/low_interaction_user_data.sh", {
    pipeline_endpoint = aws_instance.pipeline_controller.private_ip
    kafka_endpoint   = var.kafka_endpoint
  })

  tags = merge(var.tags, {
    Name = "honeynet-low-interaction-${count.index}"
  })
}

# Security Group for Low-Interaction Honeypots
resource "aws_security_group" "low_interaction_sg" {
  name        = "low-interaction-sg"
  description = "Security group for low-interaction honeypots"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH honeypot"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP honeypot"
    from_port   = 80
    to_port     = 80
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
    Name = "low-interaction-sg"
  }
}

# High-Interaction Honeypot (On-Demand)
resource "aws_instance" "high_interaction_honeypots" {
  count         = var.high_interaction_count
  ami           = var.ami_id
  instance_type  = var.high_interaction_instance_type
  key_name       = var.key_name
  subnet_id      = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.high_interaction_sg.id]
  associate_public_ip_address = false  # Isolated
  user_data      = templatefile("${path.module}/high_interaction_user_data.sh", {
    pipeline_endpoint = aws_instance.pipeline_controller.private_ip
    kafka_endpoint   = var.kafka_endpoint
  })

  tags = merge(var.tags, {
    Name = "honeynet-high-interaction-${count.index}"
  })
}

# Security Group for High-Interaction Honeypots
resource "aws_security_group" "high_interaction_sg" {
  name        = "high-interaction-sg"
  description = "Security group for high-interaction honeypots"
  vpc_id      = var.vpc_id

  # Only allow traffic from pipeline controller
  ingress {
    description = "Allow traffic from pipeline only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.pipeline_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "high-interaction-sg"
  }
}
