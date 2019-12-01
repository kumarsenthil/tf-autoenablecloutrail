  
variable "region" {
  type = string
  description = "Name of the region"
  default = "us-east-1"
}

variable "autoenable_cloudtrail" {
  default     = "true"
  description = "Specifies whether to implement autoenable cloudtrail."
}

