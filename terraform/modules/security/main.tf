# Security group for the bastion host
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = var.vpc_id

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
    description = "SSH access from allowed IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound traffic within VPC"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

# Security group for the ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = var.vpc_id

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_blocks]
    description = "HTTP access from allowed CIDR blocks"
  }

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr_blocks]
    description = "HTTPS access from allowed CIDR blocks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound traffic within VPC"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# Security group for the VPC endpoints
resource "aws_security_group" "endpoints" {
  name        = "${var.project_name}-${var.environment}-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access from within VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-endpoints-sg"
  }
}

# Security group for the ECS tasks
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for the ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_container_port
    to_port         = var.app_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Access from the ALB to backend port"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Access from the ALB to HTTP port"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH access from the bastion host"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow outbound traffic within VPC"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  }
}
