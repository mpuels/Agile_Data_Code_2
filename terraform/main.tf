provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

locals {
  ssh_user     = "ubuntu"
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

data "external" "my_public_ip" {
  program = ["bash", "my_public_ip.sh"]
}

resource "aws_security_group" "this" {
  name        = "allow-ssh-http"
  description = "Allow SSH inbound traffic and HTTP outbound traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["${data.external.my_public_ip.result.ip}/32"]
  }

  egress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${local.project_name}"
  }
}

data "template_cloudinit_config" "user_data" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config

users:
- { name: ubuntu, groups: [ wheel ], sudo: [ "ALL=(ALL) NOPASSWD:ALL" ], shell: /bin/bash, ssh-authorized-keys: [ "${var.ssh_key}" ] }
EOF
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${file("../aws/ec2_bootstrap.sh")}"
  }
}

resource "aws_instance" "this" {
  ami           = "${data.aws_ami.ubuntu-server-18-04.id}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${element(module.vpc.public_subnets, 0)}"

  vpc_security_group_ids = ["${aws_security_group.this.id}"]

  user_data = "${data.template_cloudinit_config.user_data.rendered}"

  root_block_device {
    volume_size = 256
  }

  tags {
    Name = "${local.project_name}"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.route53_hosted_zone_id}"
  name    = "${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.this.public_ip}"]
}
