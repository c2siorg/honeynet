
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  user_data = templatefile("${path.module}/user_data.sh", {
    honeypot_ips = join(",", var.honeypot_ips)
  })

  tags = {
    Name    = "honeynet-monitoring"
    Project = "honeynet"
  }
}
