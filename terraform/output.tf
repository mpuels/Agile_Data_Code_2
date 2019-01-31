output "public_ip" {
  description = "The public IP of the EC2 instance."
  value       = "${aws_instance.this.public_ip}"
}

output "my_public_ip" {
  description = "The public IP of the machine the terraform command is executed."
  value       = "${data.external.my_public_ip.result.ip}"
}
