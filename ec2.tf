provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxx"
}

data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "my_Vm" {
  ami             = data.aws_ami.app_ami.id
  instance_type   = var.instancetype
  key_name        = "xxxxxxxxxxxxxxxxxxxxxxx"
  tags            = var.aws_common_tag
  security_groups = ["${aws_security_group.allow_Http_Https_Ssh.name}"]
  
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install -y nginx1.12",
      "sudo systemctl start nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./xxxxxxxxxxxxxxxxxxxxx.pem")
      host        = self.public_ip
    }
  }
}

resource "aws_security_group" "allow_Http_Https_Ssh" {
  name        = "SG-ALLOW-22-80-443"
  description = "Allow http/https/ssh inbound traffic"

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ssh from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_Http_Https_Ssh"
  }
}

resource "aws_eip" "lb" {
  instance = aws_instance.my_Vm.id
  vpc      = true
  provisioner "local-exec" {
    command = "echo PUBLIC IP: ${aws_eip.lb.public_ip} ; ID: ${aws_instance.my_Vm.id} ; AZ: ${aws_instance.my_Vm.availability_zone}; >> infos.ec2.txt"
  }
}
