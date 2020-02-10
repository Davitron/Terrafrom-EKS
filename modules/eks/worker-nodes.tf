resource "aws_iam_role" "eks-demo-node" {
  name = "terraform-eks-demo-node"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-demo-node.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-demo-node.name
}

resource "aws_iam_role_policy_attachment" "eks-demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-demo-node.name
}

resource "aws_iam_instance_profile" "eks-demo-node" {
  name = "terraform-eks-demo"
  role = aws_iam_role.eks-demo-node.name
}

resource "aws_security_group" "eks-demo-node" {
  name        = "terraform-eks-demo-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks-demo-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
     "Name", "terraform-eks-demo-node",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
  )
}

resource "aws_security_group_rule" "eks-demo-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks-demo-node.id
  source_security_group_id = aws_security_group.eks-demo-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-demo-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-demo-node.id
  source_security_group_id = aws_security_group.eks-demo-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

locals {
  demo-node-userdata = <<USERDATA
#!/bin/bash -xe
CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.eks-demo.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.eks-demo.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster_name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${var.region},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.eks-demo.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet
USERDATA
}

resource "aws_launch_configuration" "eks-demo" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.eks-demo-node.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "m4.large"
  name_prefix                 = "terraform-eks-demo"
  security_groups             = [aws_security_group.eks-demo-node.id]
  user_data_base64            = base64encode(local.demo-node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks-demo" {
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.eks-demo.id
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-demo"
  vpc_zone_identifier  = ["${aws_subnet.eks-demo-subnet.id}"]

  tag {
    key                 = "Name"
    value               = "terraform-eks-demo"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}