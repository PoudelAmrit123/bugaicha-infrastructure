variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role for the Lambda function"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.11"
}

variable "handler" {
  type        = string
  description = "Lambda handler"
  default     = "index.handler"
}

variable "filename" {
  type        = string
  description = "Path to the Lambda function code ZIP file"
  default     = null
}

variable "source_code_hash" {
  type        = string
  description = "Base64-encoded SHA256 hash of the Lambda function code"
  default     = null
}

variable "timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 60
}

variable "memory_size" {
  type        = number
  description = "Lambda function memory in MB"
  default     = 128
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables for the Lambda function"
  default     = {}
}

variable "enable_dynamodb_policy" {
  type        = bool
  description = "Enable DynamoDB access policy for Lambda"
  default     = false
}

variable "vpc_config" {
  type = object({
    vpc_id     = string
    subnet_ids = list(string)
  })
  description = "VPC configuration for the Lambda function"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Lambda function"
  default     = {}
}
