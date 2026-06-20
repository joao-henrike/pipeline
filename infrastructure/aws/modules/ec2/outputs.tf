output "ec2_private_ip"    { value = aws_instance.private.private_ip }
output "ec2_instance_id"   { value = aws_instance.private.id }
output "bastion_public_ip" { value = var.create_bastion ? aws_instance.bastion[0].public_ip  : null }
output "bastion_id"        { value = var.create_bastion ? aws_instance.bastion[0].id : null }
output "key_pair_name"     { value = aws_key_pair.ec2_key.key_name }
output "ami_id"            { value = data.aws_ami.amazon_linux_2.id }
