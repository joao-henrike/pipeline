# =============================================================================
# MÓDULO KEY PAIR
# Gera um par de chaves RSA 4096-bit compartilhado por todas as EC2s.
# A chave privada é salva em keys/key-multicloud-<student>.pem
# =============================================================================

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "key-multicloud-${var.student_name}"
  public_key = tls_private_key.key.public_key_openssh
  tags       = { Name = "key-multicloud-${var.student_name}" }
}

resource "local_file" "private_pem" {
  content         = tls_private_key.key.private_key_pem
  filename        = "${path.root}/keys/key-multicloud-${var.student_name}.pem"
  file_permission = "0400"
}
