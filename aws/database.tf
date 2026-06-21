# Grupo de Sub-redes do RDS (Requer obrigatoriamente 2 zonas)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "techstock-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
  tags       = { Name = "TechStock DB Subnet Group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "techstock-rds"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t3.micro"
  username               = "postgres"
  password               = "TechStock2026!" # Credencial estatica para o lab
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_database.id]

  # Trava de protecao: evita que o Terraform trave no Academy ao destruir
  skip_final_snapshot = true
  publicly_accessible = false
}
