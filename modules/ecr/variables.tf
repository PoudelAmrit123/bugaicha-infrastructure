variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}


variable "enable_scan_on_push" {
  type    = bool
  default = true

}

variable "ecr_repository_name" {
  type    = string
  default = "change-this-name"

}



variable "ecr_lifecycle_policy" {
  type    = string
  default = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF


}

variable "ecr_repository_policy" {
  type    = string
  default = <<EOF
   {
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"  
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}

EOF
}


