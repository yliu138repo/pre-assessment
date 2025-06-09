variable "aws_region" {
  type        = string
  description = "AWS region where the infra will be deployed"
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the existing EC2 KeyPair"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = ""
}

variable "web_server_port" {
  type        = number
  description = "The port of the EC2 instance that the web server will listen to"
  default     = 8080
}

variable "web_server_ip" {
    type = string
    description = "The static private IP address within the assigned CIDR range"
}