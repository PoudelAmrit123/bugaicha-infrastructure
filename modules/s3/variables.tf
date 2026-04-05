# Basic Bucket Settings
variable "bucket_name" {
  description = "name of the s3 bucket"
  type        = string
}



variable "tags" {
  description = "Tags for the bucket"
  type        = map(string)
  default = {
    Name = "s3-bucket"
  }
}

# Versioning
variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

# Encryption
variable "sse_rules" {
  description = "List of encryption rules for the S3 bucket"
  type = list(object({
    sse_algorithm     = string
    kms_master_key_id = optional(string)
  }))
  default = []
}


## Enable Lifecycle rule or not

variable "enable_lifecycle_policy" {
  description = "enable the lifecycle policy or not "
  default     = true
  type        = bool

}



# Lifecycle Rules
variable "lifecycle_rules" {
  description = "List of lifecycle management rules for the S3 bucket"
  type = list(object({
    id     = string
    status = string
    prefix = optional(string)
    transition = optional(object({
      days          = number
      storage_class = string
    }))
    expiration = optional(object({
      days = number
    }))
  }))

  default = [
    {
      id         = "delete-raw"
      status     = "Enabled"
      prefix     = "raw/"
      expiration = { days = 30 }
    },
    {
      id         = "delete-rejects"
      status     = "Enabled"
      prefix     = "rejects/"
      expiration = { days = 30 }
    },
    {
      id     = "processed-to-glacier"
      status = "Enabled"
      prefix = "processed/"
      transition = {
        days          = 30
        storage_class = "GLACIER"
      }
      expiration = { days = 365 }
    },
    {
      id     = "metadata-to-glacier"
      status = "Enabled"
      prefix = "metadata/"
      transition = {
        days          = 30
        storage_class = "GLACIER"
      }
      expiration = { days = 365 }
    }
  ]
}


# Bucket Policy
variable "create_bucket_policy" {
  description = "Bucket policy JSON string"
  type        = bool
  default     = true
}


variable "bucket_policy_input" {
  description = "Complete input for the S3 bucket policy (bucket ARNs + statements)"
  type = object({
    bucket_arns = list(string)
    statement = list(object({
      Effect    = string
      Principal = any
      Action    = any
      Condition = optional(any)
    }))
  })



  default = {
    bucket_arns = []
    statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
      }
    ]
  }
}



# Public Access Block
variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets"
  type        = bool
  default     = true
}

# Optional Static Website Hosting
variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}



variable "website_index_document" {
  description = "Index document for website (e.g., index.html)"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for website (e.g., error.html)"
  type        = string
  default     = "error.html"
}