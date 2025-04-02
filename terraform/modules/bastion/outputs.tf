output "instance_id" {
  description = "The ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "The public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}
