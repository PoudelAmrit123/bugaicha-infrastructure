output "cache_id" {
  description = "The ID of the Valkey cache"
  value       = aws_elasticache_serverless_cache.valkey.id
}

output "endpoint" {
  description = "The endpoint of the Valkey cache"
  value       = aws_elasticache_serverless_cache.valkey.endpoint
}

output "arn" {
  description = "The ARN of the Valkey cache"
  value       = aws_elasticache_serverless_cache.valkey.arn
}
