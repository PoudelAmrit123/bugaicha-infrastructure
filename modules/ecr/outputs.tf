output "ecr_repository_name" {
  value = aws_ecr_repository.ecr_repository.name

}

output "ecr_repository_id" {
  value = aws_ecr_repository.ecr_repository.id

}

output "ecr_repository_uri" {
  value = aws_ecr_repository.ecr_repository.repository_url

}