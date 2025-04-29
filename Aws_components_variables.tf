# variables.tf

variable "db_master_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "admin"
}

variable "db_master_password" {
  description = "Master password for the RDS database"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
