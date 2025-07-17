resource "aws_efs_file_system" "main" {
  creation_token = "${var.name_prefix}-mongodb-storage"
  encrypted      = true

  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-mongodb-efs"
  })
}

resource "aws_security_group" "efs" {
  name        = "${var.name_prefix}-efs"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-efs-sg"
  })
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_efs_mount_target" "main" {
  count = length(var.private_subnets)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Enable automatic backups
resource "aws_efs_backup_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = "ENABLED"
  }
}
