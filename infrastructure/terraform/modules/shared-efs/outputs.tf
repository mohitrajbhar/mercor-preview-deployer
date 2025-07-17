output "file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "security_group_id" {
  description = "EFS security group ID"
  value       = aws_security_group.efs.id
}
