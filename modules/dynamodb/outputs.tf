output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.this.id
}

output "table_stream_arn" {
  description = "Stream ARN of the DynamoDB table"
  value       = aws_dynamodb_table.this.stream_arn
}

output "table_stream_label" {
  description = "Stream label of the DynamoDB table"
  value       = aws_dynamodb_table.this.stream_label
}

output "table_tags_all" {
  description = "All tags assigned to the DynamoDB table"
  value       = aws_dynamodb_table.this.tags_all
}
