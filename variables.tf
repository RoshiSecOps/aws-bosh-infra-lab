variable "instance_name" {
  description = "Value of the EC2 instance's name tag."
  type        = string
  default     = "learn-terraform"
}

variable "instance_type" {
  description = "The EC2 Instance's type"
  type        = string
  default     = "m7i-flex.large"
}

variable "availability_zone" {
  description = "Availability zone we will use"
  type        = string
  default     = "eu-central-1a"
}