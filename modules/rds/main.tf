### Subnet Group

resource "aws_db_subnet_group" "db_subnet_group" {
  count      = var.create_db_subnet_group ? 1 : 0
  name       = "main"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Key = "rds-subnet-group"
  })
}


## Security Group

resource "aws_security_group" "security_group" {
  count = var.create_security_group ? 1 : 0

  name        = var.security_group_name
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
      description      = lookup(ingress.value, "description", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
      description      = lookup(egress.value, "description", null)
    }
  }

  tags = merge(var.tags, { Name = var.security_group_name })
}


## Parameter Group

resource "aws_db_parameter_group" "db_parameter_group" {

  count  = var.create_parameter_group ? 1 : 0
  name   = var.parameter_name
  family = var.parameter_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

## Option Group

resource "aws_db_option_group" "db_option_group" {
  count = var.create_option_group ? 1 : 0

  name                     = var.option_group_name
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version
  option_group_description = "RDS option group"

  dynamic "option" {
    for_each = var.db_option
    content {
      option_name = option.value.option_name
      port        = lookup(option.value, "port", null)
      version     = lookup(option.value, "version", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(var.tags, {
    name = "db-option-group"
  })
}



# IAM ROLE For Monitoring purpose of the aws RDS

resource "aws_iam_role" "iam_role_monitoring" {
  count = var.create_monitoring_role ? 1 : 0

  name               = "${var.db_identifier}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document.json
}

data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "monitoring_attach" {
  count      = var.create_monitoring_role ? 1 : 0
  role       = aws_iam_role.iam_role_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}





#### RDS  Instance 
## if want to use the for_each but that vlaue is not in the main foreachloop 
## we can use that simple variable as the confition for the for_each and 
## loop that accross that value 

resource "aws_db_instance" "db_instance" {



  for_each   = var.enable_db_instance ? var.db_instance_config : {}
  identifier = "${var.db_identifier}-${each.key}"

  engine                = each.value.engine
  engine_version        = each.value.engine_version
  instance_class        = each.value.instance_class
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_encrypted     = each.value.storage_encrypted
  kms_key_id            = each.value.kms_key_id

  username = each.value.username
  password = each.value.password
  db_name  = each.value.db_name
  port     = each.value.port


  multi_az                            = each.value.multi_az
  publicly_accessible                 = each.value.publicly_accessible
  iam_database_authentication_enabled = each.value.iam_database_authentication_enabled

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.security_group[0].id] : var.vpc_security_group_ids
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.db_subnet_group[0].name : var.db_subnet_group_name
  parameter_group_name   = var.create_parameter_group ? aws_db_parameter_group.db_parameter_group[0].name : var.parameter_group_name
  option_group_name      = var.create_option_group ? aws_db_option_group.db_option_group[0].name : var.option_group_name

  monitoring_interval = each.value.monitoring_interval
  monitoring_role_arn = var.create_monitoring_role ? aws_iam_role.iam_role_monitoring[0].arn : var.monitoring_role_arn

  performance_insights_enabled    = each.value.performance_insights_enabled
  performance_insights_kms_key_id = each.value.performance_insights_enabled ? each.value.performance_insights_kms_key_id : null

  enabled_cloudwatch_logs_exports = each.value.enable_cloudwatch_logs_exports ? each.value.cloudwatch_log_types : []

  auto_minor_version_upgrade = each.value.enable_auto_minor_version_upgrade
  deletion_protection        = each.value.deletion_protection
  skip_final_snapshot        = each.value.skip_final_snapshot

  tags = merge(var.tags, { Name = var.db_identifier })
}


###  Multi AZ



resource "aws_rds_cluster_parameter_group" "cluster_params" {
  count       = var.is_multi_az ? 1 : 0
  name_prefix = "${var.name}-cluster-pg-"
  family      = var.multi_az_family
  description = "rds clutser paramter group"

  dynamic "parameter" {
    for_each = var.mutli_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-cluster-parameter-group"
  })
}


resource "aws_rds_cluster" "multi_az_cluster" {

  for_each = var.is_multi_az ? var.multi_db_instance_config : {}


  cluster_identifier   = each.value.name_prefix
  database_name        = each.value.database_name
  master_username      = each.value.master_username
  master_password      = each.value.master_password
  engine               = each.value.engine
  engine_version       = each.value.engine_version
  port                 = each.value.port
  db_subnet_group_name = var.create_db_subnet_group ? aws_db_subnet_group.db_subnet_group[0].name : var.db_subnet_group_name

  vpc_security_group_ids = var.create_security_group ? [aws_security_group.security_group[0].id] : var.vpc_security_group_ids
  skip_final_snapshot    = each.value.skip_final_snapshot




  storage_encrypted = each.value.storage_encrypted
  kms_key_id        = each.value.kms_key_id


  apply_immediately               = each.value.apply_immediately
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_params[0].name


  storage_type                        = each.value.storage_type
  performance_insights_enabled        = each.value.performance_insights_enabled
  performance_insights_kms_key_id     = each.value.performance_insights_enabled ? each.value.performance_insights_kms_key_id : null
  iam_database_authentication_enabled = each.value.iam_database_authentication_enabled

  # manage_master_user_password           = var.manage_master_user_password

  enabled_cloudwatch_logs_exports = each.value.enable_cloudwatch_logs_exports ? each.value.cloudwatch_log_types : []

  allocated_storage         = each.value.allocated_storage
  db_cluster_instance_class = each.value.instance_class
  tags = merge(var.tags, {
    Name = "${each.value.name_prefix}-multi-az-db-cluster"
  })
}


