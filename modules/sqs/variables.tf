variable "name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "delay_seconds" {
  type    = number
  default = 0
}

variable "max_message_size" {
  type    = number
  default = 262144
}

variable "message_retention_seconds" {
  type    = number
  default = 345600 # 4 days
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 0
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "fifo_queue" {
  type    = bool
  default = false
}

variable "content_based_deduplication" {
  type    = bool
  default = false
}

# DLQ
variable "create_dlq" {
  type    = bool
  default = true
}

variable "max_receive_count" {
  type    = number
  default = 5
}

variable "dlq_message_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}

variable "tags" {
  type    = map(string)
  default = {}
}