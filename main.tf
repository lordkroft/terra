module "module_networking" {
    source = "./modules/module_networking"
    environment = "dev"
    vpc_cidr = "192.168.0.0/16" 
    newbits_number = 8
    private_subnets = 2
    public_subnets = 2
}


