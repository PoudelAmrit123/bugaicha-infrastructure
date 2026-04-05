## VPC

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.tags,
    {
      Name    = var.vpc_name
      Project = var.vpc_project

    }
  )
}


## AWS SUBNET.. 
## Public Subnet.

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id


  count             = length(local.public_subnet)
  cidr_block        = local.public_subnet[count.index].cidr
  availability_zone = local.public_subnet[count.index].availability_zone


}


## Private Subnethelper m

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id

  count             = length(local.private_subnet)
  cidr_block        = local.private_subnet[count.index].cidr
  availability_zone = local.private_subnet[count.index].availability_zone



}


## IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  count  = var.enable_igw ? 1 : 0

  tags = merge(

    local.tags,

    {
      Project = var.vpc_project
    }

  )
}


##   Route Table for Public.. 

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  count  = var.has_public_subnet ? 1 : 0

  tags = merge(
    local.tags,
    {
      Name    = "${var.vpc_name}-public-rt"
      Project = var.vpc_project
    }

  )

}


resource "aws_route" "public_route" {

  count                  = (var.enable_igw && var.has_public_subnet) ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.igw[0].id


}



resource "aws_route_table_association" "public" {

  for_each       = var.has_public_subnet ? { for idx, s in aws_subnet.public_subnet : idx => s } : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table[0].id
}



## Route table for the private.. 


resource "aws_route_table" "private_route_table" {

  vpc_id = aws_vpc.vpc.id

  for_each = { for s in aws_subnet.private_subnet : s.availability_zone => s }

  tags = merge(
    local.tags,
    {
      Name    = "${var.vpc_name}-private-rt"
      Project = var.vpc_project
    }

  )

}



resource "aws_route" "private_route" {

  for_each = var.enable_nat_gateway ? aws_route_table.private_route_table : {}

  route_table_id = each.value.id

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id

}

resource "aws_route_table_association" "private" {




  # Always associate with the private route table unless using nat_instance overrides
  for_each  = !var.enable_nat_instance ? { for idx, s in aws_subnet.private_subnet : idx => s } : {}
  subnet_id = each.value.id

  route_table_id = aws_route_table.private_route_table[each.value.availability_zone].id

}

## Nat Gateway. 

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {

  for_each = var.enable_nat_gateway ? { for s in aws_subnet.public_subnet : s.availability_zone => s } : {}
  domain   = "vpc"



  tags = merge(
    local.tags,
    {
      Name    = "${var.vpc_name}-nat-eip-${each.key}"
      Project = var.vpc_project
    }
  )
}



resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat[each.key].id

  for_each  = var.enable_nat_gateway ? { for s in aws_subnet.public_subnet : s.availability_zone => s } : {}
  subnet_id = each.value.id

  tags = merge(
    local.tags,
    {
      Name    = "${var.vpc_name}-nat-gw"
      Project = var.vpc_project
    }

  )

  depends_on = [aws_internet_gateway.igw]
}




### NAT INSTANCE  ###


# Security group for NAT (keyed by AZ)
resource "aws_security_group" "nat" {
  for_each = var.enable_nat_instance ? { for s in aws_subnet.public_subnet : s.availability_zone => s } : {}

  name        = "nat-sg-${each.key}"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name    = "nat-sg-${each.key}"
      Project = var.vpc_project
    }

  )
}

# NAT instance (one per AZ)

resource "aws_instance" "nat" {
  for_each = var.enable_nat_instance ? { for s in aws_subnet.public_subnet : s.availability_zone => s } : {}

  ami                         = var.aws_instance_ami
  instance_type               = "t3.micro"
  subnet_id                   = each.value.id
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.nat[each.key].id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -s ${var.cidr_block} -j MASQUERADE
  EOF

  tags = {
    Name    = "${var.vpc_name}-nat-${each.key}"
    Project = var.vpc_project
  }

}


# One private route table per AZ
resource "aws_route_table" "nat_private_route_table" {
  for_each = { for s in aws_subnet.private_subnet : s.availability_zone => s }

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "${var.vpc_name}-private-rt-${each.key}"
    Project = var.vpc_project
  }
}

# Associate all private subnets with their AZ's route table
resource "aws_route_table_association" "private_assoc" {
  # for_each = var.enable_nat_instance ? { for s in aws_subnet.private_subnet : s.id => s } : {}
  for_each = var.enable_nat_instance ? { for idx, s in aws_subnet.private_subnet : idx => s } : {}


  subnet_id      = each.value.id
  route_table_id = aws_route_table.nat_private_route_table[each.value.availability_zone].id
  lifecycle {
    replace_triggered_by = [aws_route_table.nat_private_route_table]
  }
}

# Add default route in each private RT to NAT instance in that AZ
resource "aws_route" "private_nat_instance" {
  for_each = var.enable_nat_instance ? aws_route_table.nat_private_route_table : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat[each.key].primary_network_interface_id
}



## Flow logs 


resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}


resource "aws_flow_log" "vpc_flow" {
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type     = "cloud-watch-logs"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.vpc.id
  iam_role_arn             = aws_iam_role.vpc_flow_logs_role.arn
  max_aggregation_interval = 60
  tags = {
    Name    = "${var.vpc_name}-flow-log"
    Project = var.vpc_project
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = var.aws_cloudwatch_log_group
  retention_in_days = 30 # Optional: log retention
  tags = {
    Project = var.vpc_project
  }
}
