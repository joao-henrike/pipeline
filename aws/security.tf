# ==========================================
# SEGURANÇA: GERAÇÃO DE CHAVES SSH DINÂMICAS
# ==========================================

# 1. Gera o par de chaves criptográficas (RSA 4096 bits)
resource "tls_private_key" "techstock_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Injeta a Chave Pública na AWS
resource "aws_key_pair" "techstock_deployer" {
  key_name   = "techstock-dynamic-key"
  public_key = tls_private_key.techstock_key.public_key_openssh
}

# 3. Salva a Chave Privada na máquina local (pasta keys/)
resource "local_file" "private_key" {
  content         = tls_private_key.techstock_key.private_key_pem
  filename        = "${path.module}/keys/techstock-key.pem"
  file_permission = "0400" # Permissão estrita: apenas o dono pode ler
}

# Output para confirmar o nome da chave gerada
output "aws_key_pair_name" {
  value = aws_key_pair.techstock_deployer.key_name
}
