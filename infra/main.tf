provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main_igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "public_subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "private_subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for VM1
resource "aws_security_group" "vm1_sg" {
  name        = "vm1_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vm1_sg"
  }
}

# Security Group for VM2
resource "aws_security_group" "vm2_sg" {
  name        = "vm2_sg"
  description = "Allow HTTP from VM1"
  vpc_id      = aws_vpc.main.id

# TODO: remove this section for production
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["${aws_instance.vma.private_ip}/32"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.vm1_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vm2_sg"
  }
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# VM A - public subnet
data "aws_route53_zone" "selected" {
  zone_id = var.route53_zone_id
}

data "template_file" "nginx_config" {
  depends_on = [ aws_route53_record.vm_a_dns ]
  template = file("${path.module}/nginx.config.tpl")
  vars = {
    backend_ip = var.web_server_ip
    hostname = "goserver.${data.aws_route53_zone.selected.name}"
  }
}

# To ensure VM A has a static public IP address
resource "aws_eip" "vm_a_eip" {
  vpc = true
}

resource "aws_instance" "vma" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.vm1_sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install -y docker 
                # yum install -y curl

                sudo service docker start
                sudo systemctl enable docker

                mkdir -p /certs /nginx
                cat <<EOT > /nginx/nginx.conf
                ${data.template_file.nginx_config.rendered}
                EOT

                openssl req -x509 -nodes -days 365 \
                -newkey rsa:2048 \
                -keyout /certs/nginx.key \
                -out /certs/nginx.crt \
                -subj "/CN=goserver.${data.aws_route53_zone.selected.name}"

                docker run -d \
                --name nginx-proxy \
                --restart always \
                -p 443:443 \
                -v /nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
                -v /certs:/etc/nginx/certs:ro \
                nginx

              EOF
              

  tags = {
    Name = "vm_a_public_subnet"
  }
}

resource "aws_eip_association" "vm_a_eip_assoc" {
  instance_id   = aws_instance.vma.id
  allocation_id = aws_eip.vm_a_eip.id
}

# resource "aws_route53_zone" "public" {
#   name = "gowebserver.com"
# }

resource "aws_route53_record" "vm_a_dns" {
  zone_id = var.route53_zone_id
  name    = "goserver"
  type    = "A"
  ttl     = 300
  records = [aws_eip.vm_a_eip.public_ip]
}

# VM b - Web Server - private subnet
resource "aws_instance" "vmb" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  private_ip             = var.web_server_ip
  vpc_security_group_ids = [aws_security_group.vm2_sg.id]
  key_name               = aws_key_pair.deployer.key_name
  user_data              = file("user_data_web.sh")

  tags = {
    Name = "vm_b_web_server_private_subnet"
  }
}

# NAT GW to enable VM B to pull images from dockerhub
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat_eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat_gateway"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "private-rt-assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}



