# ==========================================
# VPC (using public AWS module)
# ==========================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true # Use one NAT GW to save costs in a lab
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# ==========================================
# APPLICATION LOAD BALANCER & TARGET GROUPS
# ==========================================
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "${var.app_name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Security Group allowing HTTP traffic on Prod (80) and Test (8080) ports
  security_group_ingress_rules = {
    all_http_80 = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_http_8080 = {
      from_port   = 8080
      to_port     = 8080
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    # Production Listener (Port 80)
    prod = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "blue"
      }
    }
    # Test Listener for CodeDeploy validation (Port 8080)
    test = {
      port     = 8080
      protocol = "HTTP"
      forward = {
        target_group_key = "green"
      }
    }
  }

  target_groups = {
    blue = {
      name_prefix       = "blue-"
      protocol          = "HTTP"
      port              = var.container_port
      target_type       = "ip"
      create_attachment = false
    }
    green = {
      name_prefix       = "green-"
      protocol          = "HTTP"
      port              = var.container_port
      target_type       = "ip"
      create_attachment = false
    }
  }
}

# ==========================================
# ECS TASKS SECURITY GROUP
# ==========================================
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [module.alb.security_group_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-tasks-sg"
  }
}
