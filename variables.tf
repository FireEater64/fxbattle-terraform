variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "fenris"
}

variable "instance_size" {
  description = "Desired instance size"
  default = "c5.2xlarge"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-2"
}