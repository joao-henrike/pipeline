output "instance_id" { value = aws_instance.backend.id }
output "private_ip" { value = aws_instance.backend.private_ip }
output "backend_url" { value = "http://${aws_instance.backend.private_ip}:8000" }
output "metrics_url" { value = "http://${aws_instance.backend.private_ip}:9100/metrics" }
output "ami_id" { value = data.aws_ami.al2.id }
