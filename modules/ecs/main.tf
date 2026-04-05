data "aws_ami" "ecs" {
  count       = var.launch_type == "EC2" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}



### ECS Cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  tags = var.tags
}



## ECS Services | For different service |
resource "aws_ecs_service" "ecs_service" {
  for_each = var.services

  name            = each.value.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition[each.key].arn
  desired_count   = each.value.ecs_desiredCount
  launch_type     = each.value.launch_type

  enable_execute_command = true

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" || each.value.launch_type == "FARGATE" ? [1] : []
    content {
      assign_public_ip = each.value.enable_public_ip_ecs_service
      security_groups  = [aws_security_group.ecs_service_sg[each.key].id]
      subnets          = each.value.ecsService_subnets
    }
  }

  dynamic "load_balancer" {
    for_each = each.value.enable_alb ? [1] : []

    content {
      target_group_arn = lookup(var.target_group_arns, each.key, null)
      container_name   = each.value.container_name
      container_port   = each.value.container_port
    }
  }

  #   dynamic "service_connect_configuration" {
  #   for_each = try([each.value.service_connect_configuration], [])
  #   content {
  #     enabled   = true
  #     namespace = aws_service_discovery_private_dns_namespace.service_connect_ns.name

  #     dynamic "service" {
  #       for_each = try(service_connect_configuration.value.services, [])
  #       content {
  #         port_name      = service.value.port_name
  #         discovery_name = try(service.value.discovery_name, service.value.port_name)

  #         dynamic "client_alias" {
  #           # for_each = try(service.value.client_alias, null) != null ? [service.value.client_alias] : []
  #           for_each = try(service.value.client_alias, [])
  #           content {
  #             port     = client_alias.value.port
  #           }
  #         }
  #       }
  #     }
  #   }
  # }

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

locals {
  api_autoscaling_services = var.api_autoscaling_enabled && contains(keys(var.services), var.api_service_key) ? {
    (var.api_service_key) = var.services[var.api_service_key]
  } : {}
}

resource "aws_appautoscaling_target" "api_service" {
  for_each = local.api_autoscaling_services

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.api_autoscaling_min_capacity
  max_capacity       = var.api_autoscaling_max_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service[each.key].name}"

  depends_on = [aws_ecs_service.ecs_service]
}

resource "aws_appautoscaling_policy" "api_cpu_target_tracking" {
  for_each = local.api_autoscaling_services

  name               = "${each.key}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.api_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.api_target_cpu_utilization
    scale_in_cooldown  = var.api_scale_in_cooldown
    scale_out_cooldown = var.api_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "api_memory_target_tracking" {
  for_each = local.api_autoscaling_services

  name               = "${each.key}-memory-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.api_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.api_target_memory_utilization
    scale_in_cooldown  = var.api_scale_in_cooldown
    scale_out_cooldown = var.api_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}


### Task Defination either for the fargate or EC2 service 


resource "aws_ecs_task_definition" "ecs_task_definition" {

  for_each                 = var.task
  family                   = each.value.family_name
  requires_compatibilities = [each.value.launch_type]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  network_mode             = each.value.network_mode
  execution_role_arn       = aws_iam_role.ecs_task_execution_role[each.key].arn
  task_role_arn            = aws_iam_role.ecs_task_role[each.key].arn

  dynamic "runtime_platform" {
    for_each = var.launch_type == "FARGATE" ? [1] : []
    content {
      operating_system_family = "LINUX"
      cpu_architecture        = "ARM64"
    }
  }

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = each.value.image
      essential = true
      portMappings = [
        for pm in each.value.portMappings : {
          containerPort = pm.containerPort
          hostPort      = pm.hostPort
          name          = pm.name
        }
      ]

      environment = [
        for env in lookup(each.value, "environment", []) : {
          name  = env.name
          value = env.value
        }
      ]

      secrets = [
        for sec in lookup(each.value, "secrets", []) : {
          name      = sec.name
          valueFrom = sec.valueFrom
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/am/${var.projectName}/${var.environment}/${each.key}"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "nginx"
        }
      }


    }
  ])

  depends_on = [aws_cloudwatch_log_group.ecs_services]
}

# resource "aws_service_discovery_private_dns_namespace" "service_connect_ns" {
#   name = "${var.ecs_cluster_name}.local"
#   vpc  = var.vpc_id
# }

### Roles 
### Task Definiation Role and Task Role. 

resource "aws_iam_role" "ecs_task_execution_role" {

  for_each = var.task
  name     = "${each.key}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  for_each   = var.task
  role       = aws_iam_role.ecs_task_execution_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  for_each = var.task
  name     = "${each.key}-ecs-task-execution-secrets"
  role     = aws_iam_role.ecs_task_execution_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "ecs_task_role" {
  for_each = var.task

  name = "${each.key}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "ecs_task_role_custom_policy" {
  for_each   = var.task
  role       = aws_iam_role.ecs_task_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}



##### FOR  EC2 

## Instance Profile

resource "aws_iam_role" "ecs_instance_iam_role" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  count      = var.launch_type == "EC2" ? 1 : 0
  role       = aws_iam_role.ecs_instance_iam_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "ecs-instance-profile"
  role  = aws_iam_role.ecs_instance_iam_role[0].name
}

## Launch Type 

resource "aws_launch_template" "launch_template" {

  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.ecs_cluster_name}-template"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_volume_size
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }



  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs[0].name
  }

  image_id = data.aws_ami.ecs[0].id

  instance_initiated_shutdown_behavior = "terminate"



  instance_type = var.instance_type


  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = var.enable_ip_address
    delete_on_termination       = true
    device_index                = 0
  }




  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.ecs_cluster_name}-instance"
    })
  }

  user_data = base64encode(
    <<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
      EOF
  )
}




## AUTO Scalling Group.

resource "aws_autoscaling_group" "autoscaling_group" {

  count = var.launch_type == "EC2" ? 1 : 0

  name                      = "${var.ecs_cluster_name}-asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  desired_capacity          = var.desired_capacity
  force_delete              = var.force_delete


  vpc_zone_identifier = var.subnet_id


  launch_template {
    id      = aws_launch_template.launch_template[0].id
    version = "$Latest"
  }


  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        "AmazonECSManaged" = "true"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }



}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {

  count = var.launch_type == "EC2" ? 1 : 0

  name = "cluster-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.autoscaling_group[0].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 5
      instance_warmup_period    = 120
    }
  }

  tags = merge(var.tags, {
    Name = "${var.ecs_cluster_name}-cp"
  })


}


resource "aws_ecs_cluster_capacity_providers" "capacity_providers" {

  count = var.launch_type == "EC2" ? 1 : 0

  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider[0].name
    weight            = 1


  }
  depends_on = [aws_ecs_capacity_provider.ecs_capacity_provider]
}




### Security Group

resource "aws_security_group" "ec2_instance_sg" {
  count       = var.launch_type == "EC2" ? 1 : 0
  name        = "${var.ecs_cluster_name}-ec2-instance-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.ecs_cluster_name}-ecs-instance-sg" })
}


resource "aws_security_group" "ecs_service_sg" {
  for_each = var.services

  name        = "${each.key}-service-sg"
  description = "Security group for ECS service ${each.key}"
  vpc_id      = var.vpc_id


  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${each.key}-service-sg" })
}



### Log group


resource "aws_cloudwatch_log_group" "ecs_services" {
  for_each = var.services

  name              = "/ecs/am/${var.projectName}/${var.environment}/${each.key}"
  retention_in_days = 14
}