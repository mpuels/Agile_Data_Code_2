variable "region" {
  description = "The region to deploy the EC2 instance to."
}

variable "profile" {
  description = "The AWS profile to use."
}

variable "instance_type" {
  description = "Type of the EC2 instance"
}

variable "ssh_key" {
  description = "The public SSH key to deploy to the instance."
}

variable "route53_hosted_zone_id" {
  description = "Route 53 hosted zone id"
}

variable "domain_name" {
  description = "The domain to attach to the EC2 instance"
}
