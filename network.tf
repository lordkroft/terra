module "aws_vpc" {
    source = "./modules/module-networking"
    environment = ""
    vpc_cidr = "10.0.0.0/16" 
    availability_zones = [
        "us-east-2a",
        "us-east-2b",
    ]
    
    private_subnets = 2
    public_subnets  = 2	
    newbits 		      = 8

}