module "module_networking" {
  source      = "./modules/module_networking"
  environment = var.environment

  vpc_cidr        = "192.168.0.0/16"
  newbits_number  = 8
  private_subnets = 2
  public_subnets  = 2

}


module "ecs" {
  source          = "./modules/module_ecs"
  vpc_id          = module.module_networking.vpc_id
  private_subnets = module.module_networking.private_subnets_ids
  public_subnets  = module.module_networking.public_subnets_ids
  bastion_sg      = aws_security_group.bastion_sg.id
}

