locals {

  private_subnet = var.private_subnet
  public_subnet  = var.public_subnet
  # env = terraform.workspace

  tags = {
    env = terraform.workspace
  }

}

# locals {
#   public_subnet_map = {
#     for idx, s in local.public_subnet :
#     "${s.availability_zone}-${idx}" => s
#   }

#   private_subnet_map = {
#     for idx, s in local.private_subnet :
#     "${s.availability_zone}-${idx}" => s
#   }
# }


# locals {

#   private_subnet =  var.private_subnet 
#   public_subnet =   var.public_subnet
#   # env = terraform.workspace

#   tags ={
#     env  = terraform.workspace
#   }

# }






# locals {

#   public_subnet = {
#     for idx, s in var.var.public_subnet :
#     "${s.availability_zone}-${idx}" => s
#   }

#   private_subnet = {
#     for idx, s in var.private_subnet :
#     "${s.availability_zone}-${idx}" => s
#   }

#  tags ={

#    env  = terraform.workspace

#   }
# }




