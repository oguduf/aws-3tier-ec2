resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-${var.environment}-mysql"
  engine                 = "mysql"
  engine_version         = "8.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Project     = var.project_name
    Environment = var.environment
  }
}