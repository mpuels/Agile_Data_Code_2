variable "region" {
  description = "The region to deploy the EC2 instance to."
}

variable "profile" {
  description = "The AWS profile to use."
}

variable "instance_type" {
  description = "Type of the EC2 instance"
}

variable "ssh_user" {
  description = "The SSH user corresponding to ssh_key."
}

variable "ssh_key" {
  description = "The public SSH key to deploy to the instance."
}
