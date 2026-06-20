output "instance_id"   { value = aws_instance.frontend.id }
output "public_ip"     { value = aws_instance.frontend.public_ip }
output "private_ip"    { value = aws_instance.frontend.private_ip }
output "frontend_url"  { value = "http://${aws_instance.frontend.public_ip}" }
output "node_url"      { value = "http://${aws_instance.frontend.public_ip}:3000" }
output "ami_id"        { value = data.aws_ami.al2.id }
