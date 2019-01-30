provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

locals {
  project_name = "agile-data-science"
}

data "aws_ami" "ubuntu-server-18-04" {
  most_recent = true

  filter {
    name   = "owner-id"
    values = ["099720109477"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project_name}"
  cidr = "10.0.0.0/16"
  azs  = ["${var.region}a"]

  public_subnets = ["10.0.0.0/24"]

  tags = {
    Name = "${local.project_name}"
  }
}

resource "aws_security_group" "ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${local.project_name}"
  }
}

resource "aws_instance" "this" {
  ami           = "${data.aws_ami.ubuntu-server-18-04.id}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${element(module.vpc.public_subnets, 0)}"

  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]

  user_data = <<EOF
#cloud-config

users:
- { name: ${var.ssh_user}, groups: [ wheel ], sudo: [ "ALL=(ALL) NOPASSWD:ALL" ], shell: /bin/bash, ssh-authorized-keys: [ "${var.ssh_key}" ] }
EOF

  tags {
    Name = "${local.project_name}"
  }
}
