output "vma_public_ip" {
  description = "Public IP of VM A"
  value       = aws_instance.vma.public_ip
}

output "vma_public_eip" {
  description = "Public Elastic IP of VM A"
  value       = aws_eip.vm_a_eip.public_ip
}

output "vma_private_ip" {
  description = "Private IP of VM A"
  value       = aws_instance.vma.private_ip
}

output "vmb_public_ip" {
  description = "Public IP of VM B (Web Server)"
  value       = aws_instance.vmb.public_ip
}

output "vmb_private_ip" {
  description = "Private IP of VM B (Web Server)"
  value       = aws_instance.vmb.private_ip
}