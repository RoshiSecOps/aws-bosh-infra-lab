output "instance_hostname" {
  description = "hostname of instance"
  value       = aws_instance.app_server.private_dns
}

output "instance_ip" {
  description = "IP of instsance"
  value       = aws_eip.bosh-eip.public_ip
}