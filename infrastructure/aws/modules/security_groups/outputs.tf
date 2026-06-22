output "frontend_sg_id" { value = aws_security_group.frontend.id }
output "backend_sg_id" { value = aws_security_group.backend.id }
output "monitoring_sg_id" { value = aws_security_group.monitoring.id }
# Alias para compatibilidade com módulos antigos
output "ec2_private_sg_id" { value = aws_security_group.backend.id }
output "bastion_sg_id" { value = aws_security_group.frontend.id }
