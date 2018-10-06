variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "instance_size" {
  description = "Desired instance size"
  default = "Standard_DS2_v2"
}

variable "azure_region" {
  description = "Azure location to create resources in"
  default     = "westeurope"
}

variable "environment" {
  description = "Default value for environment tag"
  default     = "Production"
}
