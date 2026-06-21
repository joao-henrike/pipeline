output "key_pair_name"     { value = aws_key_pair.key.key_name }
output "public_key_openssh"{ value = tls_private_key.key.public_key_openssh }
