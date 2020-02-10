resource "aws_vpc" "eks-demo-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = map(
      "Name", "terraform-eks-demo",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_subnet" "eks-demo-subnet" {
  vpc_id = aws_vpc.eks-demo-vpc.id

  cidr_block        = var.subnet_cidr
  availability_zone = "eu-west-1b"

  tags = map(
      "Name", "terraform-eks-demo",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_subnet" "eks-demo-subnet2" {
  vpc_id = aws_vpc.eks-demo-vpc.id

  cidr_block        = var.subnet_cidr2
  availability_zone = "eu-west-1c"

  tags = map(
      "Name", "terraform-eks-demo",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_internet_gateway" "eks-demo-gw" {
  vpc_id = aws_vpc.eks-demo-vpc.id

  tags = {
    Name = "terraform-eks-demo"
  }
}

resource "aws_route_table" "eks-demo-rt" {
  vpc_id = aws_vpc.eks-demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-demo-gw.id
  }
}

resource "aws_route_table_association" "eks-demo-rt-ass" {
  subnet_id      = aws_subnet.eks-demo-subnet.id
  route_table_id = aws_route_table.eks-demo-rt.id
}

resource "aws_route_table_association" "eks-demo-rt-ass2" {
  subnet_id      = aws_subnet.eks-demo-subnet2.id
  route_table_id = aws_route_table.eks-demo-rt.id
}