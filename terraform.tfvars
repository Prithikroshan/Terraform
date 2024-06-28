
vpc_cidr                = "10.0.0.0/16"
public_subnet_1_cidr    = "10.0.1.0/24"
private_subnet_1_cidr   = "10.0.4.0/24"
public_subnet_2_cidr    = "10.0.2.0/24"
availability_zones      = ["eu-north-1a", "eu-north-1b"]

health_check_path       = "/"
instance_type           = "t3.micro"
ec2_instance_name       = "public_instance"

ssh_pubkey_file         = "~/.ssh/aws/key.pub"

autoscale_min           = 2
autoscale_max           = 2
autoscale_desired       = 2
amis = "ami-011e54f70c1c91e17" 