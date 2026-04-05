variable "cache_name" {
  description = "Name of the Valkey cache"
  type        = string
}

variable "engine" {
  description = "The cache engine - valkey or redis"
  type        = string
  default     = "valkey"
}

variable "engine_version" {
  description = "The engine version"
  type        = string
  default     = "8"
}

variable "description" {
  description = "Description of the cache"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cache"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the cache"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the cache"
  type        = map(string)
  default     = {}
}
