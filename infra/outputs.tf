output "vma_public_ip" {
  description = "Public IP of VM A"
  value       = aws_instance.vma.public_ip
}

output "vmb_private_ip" {
  description = "Private IP of VM B (Web Server)"
  value       = aws_instance.vmb.private_ip
}