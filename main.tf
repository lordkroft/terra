module "module-networking" {
    source = "./modules/module-networking"
    environment = "dev"
    vpc_cidr = "192.168.0.0/16" 
    # availability_zones = ["us-east-2a", "us-east-2b"]
    newbits_number = 8
    private_subnets = 2
    public_subnets = 2
}


