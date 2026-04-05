# AWS ElastiCache Serverless for Valkey
resource "aws_elasticache_serverless_cache" "valkey" {
  engine              = var.engine
  name                = var.cache_name
  description         = trimspace(var.description) == "" ? " " : var.description
  major_engine_version  = var.engine_version
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids

  tags = var.tags
}
