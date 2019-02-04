output "public_ip" {
  description = "The public IP of the EC2 instance."
  value       = "${aws_instance.this.public_ip}"
}

output "my_public_ip" {
  description = "The public IP of the machine the terraform command is executed."
  value       = "${data.external.my_public_ip.result.ip}"
}

output "ssh_user_at_ip" {
  description = "The user and public IP to use for SSH."
  value       = "${local.ssh_user}@${aws_instance.this.public_ip}"
}

output "ssh_user_at_fqdn" {
  description = "The user and FQDN to use for SSH."
  value       = "${local.ssh_user}@${aws_route53_record.www.name}"
}
