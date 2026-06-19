resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_rds_a.id, aws_subnet.private_rds_b.id]
}

resource "aws_db_instance" "estoque_db" {
  identifier             = "techstock-db-master"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "techstock_estoque"
  username               = "admin_techstock"
  password               = "MasterAdmin#2026!"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.sg_database.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags                   = { Name = "rds-banco-techstock" }
}
