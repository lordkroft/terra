module "dev_vpc" {
    source = "./modules/module-networking"
    environment = "dev"
    vpc_cidr = "10.0.0.0/16" 
    # availability_zones = [
    #     "us-east-2a",
    #     "us-east-2b",
    # ]
    
   newbits_number = 8
   private_subnets = 2
   public_subnets = 2

}