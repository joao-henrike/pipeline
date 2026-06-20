output "instance_id"     { value = aws_instance.monitoring.id }
output "public_ip"       { value = aws_instance.monitoring.public_ip }
output "private_ip"      { value = aws_instance.monitoring.private_ip }
output "grafana_url"     { value = "http://${aws_instance.monitoring.public_ip}:3000" }
output "prometheus_url"  { value = "http://${aws_instance.monitoring.public_ip}:9090" }
output "alertmanager_url"{ value = "http://${aws_instance.monitoring.public_ip}:9093" }
