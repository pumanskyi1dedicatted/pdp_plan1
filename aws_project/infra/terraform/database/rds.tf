resource "aws_db_instance" "fresh-deploy-rds" {
  identifier                  = "fresh-deploy-rds"
  instance_class              = "db.t3.micro"
  allocated_storage           = 20
  storage_type                = "gp3"
  engine                      = "postgres"
  engine_version              = "18"
  auto_minor_version_upgrade  = true
  db_name                     = "bankapi"
  storage_encrypted           = true
  username                    = "dbuser"
  manage_master_user_password = true
  deletion_protection         = false
  multi_az                    = false
  db_subnet_group_name        = aws_db_subnet_group.fresh_deploy_db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  publicly_accessible         = false
  skip_final_snapshot         = true
  backup_retention_period     = 7
}


resource "aws_db_subnet_group" "fresh_deploy_db_subnet_group" {
  name       = "fresh-deploy-subnet-group"
  subnet_ids = [data.terraform_remote_state.network.outputs.database_subnet_id_eu_north_1a, data.terraform_remote_state.network.outputs.database_subnet_id_eu_north_1b]

  tags = {
    Name = "fresh-deploy"
  }
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Allow inbound traffic only for PostgreSQL"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags = {
    Name = "rds_security_group"
  }
}


