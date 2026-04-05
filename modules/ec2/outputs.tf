output "instance_id" {
  description = "The ID of the instance"
  value       = aws_instance.ec2_instance.id
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = aws_instance.ec2_instance.private_ip
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.ec2_instance.public_ip
}

output "primary_network_interface_id" {
  description = "The primary network interface ID"
  value       = aws_instance.ec2_instance.primary_network_interface_id
}