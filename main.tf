locals {
  executor_env_keys = [
    "EXECUTOR_API_BEARER_TOKEN",
    "EXECUTOR_CORS_ALLOW_ORIGINS",
    "EXECUTOR_PERSISTENCE_BACKEND",
    "EXECUTOR_DYNAMODB_TABLE_NAME",
    "EXECUTOR_ATTACHMENTS_BUCKET_NAME",
    "AWS_DEFAULT_REGION",
    "EXECUTOR_DISPATCH_BACKEND",
    "EXECUTOR_AWS_REGION",
    "EXECUTOR_SQS_PLANNING_QUEUE_URL",
    "EXECUTOR_SQS_EXECUTION_QUEUE_URL",
    "EXECUTOR_SQS_INDEX_QUEUE_URL",
    "EXECUTOR_REDIS_URL",
    "EXECUTOR_EXECUTOR_IMAGE",
    "EXECUTOR_EXECUTOR_NETWORK_MODE",
    "EXECUTOR_JOB_WORK_ROOT",
    "EXECUTOR_ATTACHMENTS_ROOT",
    "API_BEARER_TOKEN",
    "EXECUTOR_WORKER_POLL_INTERVAL_SECONDS",
    "EXECUTOR_WORKER_MAX_PARALLEL_JOBS",
    "EXECUTOR_RESULT_RETENTION_DAYS",
    "EXECUTOR_DOCKER_MEMORY_LIMIT",
    "EXECUTOR_DOCKER_CPU_LIMIT",
    "EXECUTOR_LLM_PROVIDER",
    "EXECUTOR_LLM_MODEL",
    "EXECUTOR_LLM_PLANNER_MODEL",
    "EXECUTOR_LLM_EXECUTOR_MODEL",
    "EXECUTOR_LLM_BEDROCK_REGION",
    "EXECUTOR_GITHUB_TOKEN",
    "EXECUTOR_GITHUB_API_URL",
    "EXECUTOR_GITHUB_APP_ID",
    "EXECUTOR_GITHUB_APP_PRIVATE_KEY",
    "EXECUTOR_GITHUB_APP_PRIVATE_KEY_ARN",
    "EXECUTOR_GITHUB_APP_WEBHOOK_SECRET",
    "EXECUTOR_GITHUB_APP_SLUG",
    "EXECUTOR_JIRA_BASE_URL",
    "EXECUTOR_JIRA_USER_EMAIL",
    "EXECUTOR_JIRA_API_TOKEN",
    "EXECUTOR_DOC_FETCH_TIMEOUT_SECONDS",
    "EXECUTOR_DEFAULT_BRANCH_PREFIX",
    "EXECUTOR_GIT_AUTHOR_NAME",
    "EXECUTOR_GIT_AUTHOR_EMAIL",
    "EXECUTOR_MAX_REPAIR_LOOPS",
    "EXECUTOR_COMMAND_TIMEOUT_SECONDS",
    "EXECUTOR_CONTEXT_MAX_FILE_BYTES",
    "EXECUTOR_CONTEXT_MAX_TOTAL_BYTES",
    "EXECUTOR_PLANNER_RETRIEVAL_TOKEN_BUDGET",
    "EXECUTOR_DEVELOPER_RETRIEVAL_TOKEN_BUDGET",
    "EXECUTOR_REVIEWER_RETRIEVAL_TOKEN_BUDGET",
    "EXECUTOR_PAGEINDEX_MAX_FILE_BYTES",
    "EXECUTOR_PAGEINDEX_CHUNK_LINE_LIMIT",
    "EXECUTOR_PAGEINDEX_CHUNK_LINE_OVERLAP",
    "EXECUTOR_COCOINDEX_DATABASE_URL",
    "EXECUTOR_COCOINDEX_EMBEDDING_MODEL",
    "EXECUTOR_PLANNER_IDLE_TIMEOUT_SECONDS",
    "EXECUTOR_EFS_PLANNER_ROOT",
    "EXECUTOR_ASSETS_ROOT",
    "EXECUTOR_CHROMADB_HOST",
    "EXECUTOR_CHROMADB_PORT",
    "EXECUTOR_CHROMADB_SSL",
    "EXECUTOR_CHROMADB_API_KEY",
    "DEBUGGER_MODEL_ID",
    "EMBEDDING_MODEL_ID",
    "CHROMADB_COLLECTION",
    "COCOINDEX_DATABASE_URL",
    "EXECUTOR_POSTGRES_HOST",
    "EXECUTOR_POSTGRES_PORT",
    "EXECUTOR_POSTGRES_DB",
    "EXECUTOR_POSTGRES_USER",
    "EXECUTOR_POSTGRES_PASSWORD",
    "EXECUTOR_FRONTEND_URL",
  ]
}



### VPC ####
module "vpc" {
  source                 = "./modules/vpc"
  vpc_name               = "bugai-cha"
  enable_nat_gateway     = var.enable_nat_gateway
  has_private_subnet     = var.has_private_subnet
  has_public_subnet      = var.has_public_subnet
  cidr_block             = var.vpc_cidr
  destination_cidr_block = var.destination_cidr_block
  public_subnet          = var.public_subnet
  private_subnet         = var.private_subnet
  vpc_project            = var.vpc_project
  enable_igw             = var.enable_igw

  enable_nat_instance = var.enable_nat_instance

}

## DynamoDB ##
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "bugAiCha"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attributes = [
    { name = "sk", type = "S" },
    { name = "pk", type = "S" }
  ]

  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true
  stream_enabled                 = true
  stream_view_type               = "NEW_AND_OLD_IMAGES"

  ttl_enabled        = true
  ttl_attribute_name = "expires_at"

  tags = {
    Name    = "bugAiCha-metadata"
    Project = "bugAicha"
  }
}

## Redis/Valkey ##
### REDIS ####
module "redis" {
  source = "./modules/redis"

  cache_name        = "bugaicha-redis"
  engine            = "valkey"
  engine_version    = "8"
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.redis_sg.id]

  tags = {
    Name    = "bugaicha-redis"
    Project = "bugAicha"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "bugaicha-redis-sg"
  description = "Security group for Valkey cache"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "bugaicha-redis-sg"
    Project = "bugAicha"
  }
}

## Lambda ##

### Lambda API Function ###
module "lambda_api" {
  source = "./modules/lambda"

  function_name          = "bugAiCha-api-function"
  role_name              = "bugAiCha-api-lambda-role"
  runtime                = "python3.14"
  handler                = "index.handler"
  timeout                = 500
  memory_size            = 128
  enable_dynamodb_policy = true


  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    ENVIRONMENT    = "dev"
  }

  vpc_config = {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnet_ids
  }

  tags = {
    Name    = "bugAiCha-lambda"
    Project = "bugAicha"
  }
}

### Lambda Execution Function ###
module "lambda_execution_run" {
  source = "./modules/lambda"

  function_name          = "bugAiCha-execution_run-function"
  role_name              = "bugAiCha-execution-lambda-role"
  runtime                = "python3.14"
  handler                = "index.handler"
  timeout                = 500
  memory_size            = 128
  enable_dynamodb_policy = true


  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    ENVIRONMENT    = "dev"
  }

  vpc_config = {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnet_ids
  }

  tags = {
    Name    = "bugAiCha-lambda"
    Project = "bugAicha"
  }
}

## Lambda Repository Index ##
module "lambda_repository_index" {
  source = "./modules/lambda"

  function_name          = "bugAiCha-repository_index-function"
  role_name              = "bugAiCha-repo-index-lambda-role"
  runtime                = "python3.14"
  handler                = "index.handler"
  timeout                = 500
  memory_size            = 128
  enable_dynamodb_policy = true


  environment_variables = {
    DYNAMODB_TABLE = module.dynamodb.table_name
    ENVIRONMENT    = "dev"
  }

  vpc_config = {
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnet_ids
  }

  tags = {
    Name    = "bugAiCha-lambda"
    Project = "bugAicha"
  }
}

## ECR ###
module "bugaicha-planner" {
  source              = "./modules/ecr"
  ecr_repository_name = "bugaicha-planner"
}

module "bugaicha-api" {
  source              = "./modules/ecr"
  ecr_repository_name = "bugaicha-api-backend"

}

module "bugaicha-indexer" {
  source              = "./modules/ecr"
  ecr_repository_name = "bugaicha-indexer"
}

module "bugaicha-execution" {
  source = "./modules/ecr"
  ecr_repository_name = "bugaicha-execution"
  
}

###next 

# module "bugaicha-lambda_api" {
#   source              = "./modules/ecr"
#   ecr_repository_name = "bugaicha-api-lambda"
# }


# SQS ## 
module "sqs" {
  source = "./modules/sqs"

  name              = "bugaicha-api-to-planner-queue"
  create_dlq        = false
  max_receive_count = 3

  tags = {
    Team = "bugAiCha"

  }
}

module "sqs_indexer" {
  source = "./modules/sqs"

  name              = "bugaicha-api-to-indexer-queue"
  create_dlq        = false
  max_receive_count = 3

  tags = {
    Team = "bugAiCha"

  }
}

module "sqs_executer" {
  source = "./modules/sqs"

  name              = "bugaicha-execution-queue"
  create_dlq        = false
  max_receive_count = 3

  tags = {
    Team = "bugAiCha"

  }
}

### Secrets Manager ###
data "aws_secretsmanager_secret" "planner_secrets" {
  name = "bugaicha-planner-secrets"
}

data "aws_secretsmanager_secret" "api_secrets" {
  name = "bugaicha-api-secrets"
}

data "aws_secretsmanager_secret" "indexer_secrets" {
  name = "bugaicha-indexer-secrets"
}




### EC2 ####

module "ec2" {
  source                      = "./modules/ec2"
  ami_id                      = "ami-0bdd88bd06d16ba03"
  name                        = "croma"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  associate_public_ip_address = true
  # user_data =  file("userdata.sh")
  vpc_id   = module.vpc.vpc_id
  key_name = "bugaicha-croma"
}

### ALB ####

module "alb" {
  source = "./modules/alb"

  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.public_subnet_ids
  environment = "dev"
  alb_name    = "bugaicha-api-alb"

  lb_target_groups = [
    {
      name              = "api"
      target_group_port = 8000
      protocol          = "HTTP"
      health_check = {
        path    = "/healthz"
        matcher = "200-499"
      }
    }
  ]

  lb_listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_actions = [
        {
          type             = "forward"
          target_group_key = "api"
        }
      ]
    }
  ]
}

# ##### ECS #### 
module "ecs" {
  source           = "./modules/ecs"
  ecs_cluster_name = "bugaicha"
  vpc_id           = module.vpc.vpc_id
  subnet_id        = module.vpc.public_subnet_ids
  launch_type      = "FARGATE"
  api_autoscaling_enabled       = true
  api_service_key               = "api"
  api_autoscaling_min_capacity  = 1
  api_autoscaling_max_capacity  = 6
  api_target_cpu_utilization    = 65
  api_target_memory_utilization = 75
  api_scale_in_cooldown         = 120
  api_scale_out_cooldown        = 60

  target_group_arns = {
    api = module.alb.lb_target_group_arns["api"]
  }

  services = {
    planner = {
      ecs_service_name             = "planner"
      ecs_desiredCount             = 1
      launch_type                  = "FARGATE"
      enable_alb                   = false
      enable_public_ip_ecs_service = true
      ecsService_subnets           = module.vpc.public_subnet_ids
      container_name               = "planner"
      container_port               = 80

    }

    api = {
      ecs_service_name             = "api"
      ecs_desiredCount             = 1
      launch_type                  = "FARGATE"
      enable_alb                   = true
      enable_public_ip_ecs_service = true
      ecsService_subnets           = module.vpc.public_subnet_ids
      container_name               = "api"
      container_port               = 8000
    }

    indexer = {
      ecs_service_name             = "indexer"
      ecs_desiredCount             = 1
      launch_type                  = "FARGATE"
      enable_alb                   = false
      enable_public_ip_ecs_service = true
      ecsService_subnets           = module.vpc.public_subnet_ids
      container_name               = "indexer"
      container_port               = 80
    }

     execution = {
      ecs_service_name             = "execution"
      ecs_desiredCount             = 1
      launch_type                  = "FARGATE"
      enable_alb                   = false
      enable_public_ip_ecs_service = true
      ecsService_subnets           = module.vpc.public_subnet_ids
      container_name               = "execution"
      container_port               = 80
     }

  }

  task = {
    planner = {
      containerPort = 80
      launch_type   = "FARGATE"
      cpu           = "256"
      memory        = "512"
      network_mode  = "awsvpc"
      image         = module.bugaicha-planner.ecr_repository_uri
      hostPort      = 80
      family_name   = "planner-family"

      secrets = [
        for key in local.executor_env_keys : {
          name      = key
          valueFrom = "${data.aws_secretsmanager_secret.api_secrets.arn}:${key}::"
        }
      ]
    }

    api = {
      containerPort = 8000
      launch_type   = "FARGATE"
      cpu    = "1024"
      memory = "2048"
      network_mode  = "awsvpc"
      image         = module.bugaicha-api.ecr_repository_uri
      hostPort      = 8000
      family_name   = "backend-family"

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          name          = "backend"
        }
      ]

      secrets = [
        for key in local.executor_env_keys : {
          name      = key
          valueFrom = "${data.aws_secretsmanager_secret.api_secrets.arn}:${key}::"
        }
      ]
    }


    indexer = {
      containerPort = 80
      launch_type   = "FARGATE"
      cpu           = "256"
      memory        = "512"
      network_mode  = "awsvpc"
      image         = module.bugaicha-indexer.ecr_repository_uri
      hostPort      = 80
      family_name   = "indexer-family"

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          name          = "indexer"
        }
      ]

      secrets = [
        for key in local.executor_env_keys : {
          name      = key
          valueFrom = "${data.aws_secretsmanager_secret.api_secrets.arn}:${key}::"
        }
      ]
    }

    execution = {
      containerPort = 80
      launch_type   = "FARGATE"
      cpu           = "256"
      memory        = "512"
      network_mode  = "awsvpc"
      image         = module.bugaicha-execution.ecr_repository_uri
      hostPort      = 80
      family_name   = "execution-family"

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          name          = "execution"
        }
      ]

      secrets = [
        for key in local.executor_env_keys : {
          name      = key
          valueFrom = "${data.aws_secretsmanager_secret.api_secrets.arn}:${key}::"
        }
      ]
    }


  }

}




#### RDS #### 
#  module "rds" {
#     source = "./modules/rds"

#     multi_az_family =  var.multi_az_family 
#     mutli_parameters =    var.mutli_parameters

#     engine               = var.rds_engine
#     major_engine_version = var.major_engine_version

#     subnet_ids =  module.vpc.private_subnet_ids
#     vpc_id =  module.vpc.vpc_id

#     parameter_name         = var.parameter_name
#     parameter_family       = var.parameter_family
#     parameters = var.parameters

#     db_option = var.db_option
#     db_instance_config = var.db_instance_config  

#  }


### S3 ##### 
module "s3-metadata" {
  source = "./modules/s3"

  bucket_name          = "bugaicha-metadata-bucket"
  create_bucket_policy = true
  enable_website       = false

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  bucket_policy_input = {
    bucket_arns = ["arn:aws:s3:::bugaicha-metadata-bucket"]

    statement = [
      {
        Effect = "Allow"

        Principal = "*"

        Action = [
          "s3:GetObject"
        ]

        Resource = [
          "arn:aws:s3:::bugaicha-metadata-bucket/*"
        ]
      }
    ]
  }
}

output "api_alb_url" {
  description = "The HTTP URL of the API Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}
