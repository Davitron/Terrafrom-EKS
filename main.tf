provider "aws" {
  region  = var.region
  profile = "default"
}

module "vpc" {
  source              = "./modules/network"
  cidr                = "10.0.0.0/16"
  vpc_name            = "aws"
  cluster_name        = "ays"
  master_subnet_cidr  = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
  worker_subnet_cidr  = ["10.0.144.0/20", "10.0.160.0/20", "10.0.176.0/20"]
  # public_subnet_cidr  = ["10.0.204.0/22", "10.0.208.0/22", "10.0.212.0/22"]
  # private_subnet_cidr = ["10.0.228.0/22", "10.0.232.0/22", "10.0.236.0/22"]
}

module "eks" {
  source                        = "./modules/cluster"
  vpc_id                        = module.vpc.vpc_id
  cluster-name                  = var.cluster-name
  eks_subnets                   = [module.vpc.master_subnet]
  worker_subnet                 = [module.vpc.worker_node_subnet]
  subnet_ids                    = [module.vpc.master_subnet, module.vpc.worker_node_subnet]
}

module "ingress-controller" {
  source                         = "./modules/ingress-controller"
  region                         = var.region
  vpc_id                         = module.vpc.vpc_id
  cluster_name                   = module.eks.cluster-name
  ingress_controller_file        = "./modules/ingress-controller/alb-ingress-controller.yaml"
  rbac_file                      = "./modules/ingress-controller/rbac-role.yaml"
}