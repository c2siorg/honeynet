# Honeywall Gateway Instance
resource "aws_instance" "honeywall" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = [aws_security_group.honeywall_sg.id]
  associate_public_ip_address = true
  user_data      = templatefile("${path.module}/user_data.sh", {
    elasticsearch_endpoint = var.elasticsearch_endpoint
    logstash_endpoint      = var.logstash_endpoint
  })

  tags = merge(var.tags, {
    Name = "honeynet-honeywall"
  })
}

# Security Group for Honeywall
resource "aws_security_group" "honeywall_sg" {
  name        = "honeywall-sg"
  description = "Security group for Honeywall gateway"
  vpc_id      = var.vpc_id

  # Allow all incoming traffic for inspection
  ingress {
    description = "Allow all traffic for inspection"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "honeywall-sg"
  }
}

# Network Interface for Honeypot Backend
resource "aws_network_interface" "honeypot_backend" {
  subnet_id       = var.subnet_id
  private_ips     = [var.honeypot_private_ip]
  security_groups = [aws_security_group.honeypot_backend_sg.id]

  tags = {
    Name = "honeypot-backend-nic"
  }
}

# Security Group for Honeypot Backend Network
resource "aws_security_group" "honeypot_backend_sg" {
  name        = "honeypot-backend-sg"
  description = "Security group for honeypot backend network"
  vpc_id      = var.vpc_id

  # Only allow traffic from honeywall
  ingress {
    description = "Allow traffic from honeywall only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.honeywall_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "honeypot-backend-sg"
  }
}

# Attach network interface to honeypot instance
resource "aws_network_interface_attachment" "honeypot_attachment" {
  instance_id          = var.honeypot_instance_id
  network_interface_id = aws_network_interface.honeypot_backend.id
  device_index         = 1
}
