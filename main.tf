resource "aws_vpc" "vpc-k8s" {
  provider = aws.us-east-1

  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink_dns_support   = true
  enable_classiclink               = true
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_subnet" "subnet-2" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.vpc-k8s.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_subnet" "subnet-1" {
  provider = aws.us-east-1

  vpc_id                  = aws_vpc.vpc-k8s.id
  map_public_ip_on_launch = true
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_internet_gateway" "gtw" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.vpc-k8s.id

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_route_table" "default-route" {
  provider = aws.us-east-1

  vpc_id = aws_vpc.vpc-k8s.id

  route {
    gateway_id = aws_internet_gateway.gtw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    env      = "Staging"
    archUUID = "db83bcc0-696a-4f64-a6d5-fcc143caf3e2"
  }
}

resource "aws_route_table_association" "route-association-2" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.default-route.id
}

resource "aws_route_table_association" "route-association-1" {
  provider = aws.us-east-1

  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.default-route.id
}

resource "aws_iam_role" "default-iam" {
  provider = aws.us-east-1

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

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  provider = aws.us-east-1

  role       = aws_iam_role.default-iam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  provider = aws.us-east-1

  role       = aws_iam_role.default-iam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  provider = aws.us-east-1

  role       = aws_iam_role.default-iam.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "eks-default" {
  provider = aws.us-east-1

  node_role_arn   = aws_iam_role.default-iam.arn
  node_group_name = "SAS-k8s"
  cluster_name    = aws_eks_cluster.default-cluster.name

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  scaling_config {
    min_size     = 1
    max_size     = 1
    desired_size = 1
  }

  subnet_ids = [
    aws_subnet.subnet-1.id,
    aws_subnet.subnet-2.id,
  ]

  tags = {
    env      = "Staging"
    archUUID = "db83bcc0-696a-4f64-a6d5-fcc143caf3e2"
  }
}

resource "aws_iam_role" "iam-cluster" {
  provider = aws.us-east-1

  name               = "SAS-k8s-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  provider = aws.us-east-1

  role       = aws_iam_role.iam-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  provider = aws.us-east-1

  role       = aws_iam_role.iam-cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_security_group" "cluster-sg" {
  provider = aws.us-east-1

  vpc_id      = aws_vpc.vpc-k8s.id
  name        = "SAS-k8s-cluster"
  description = "Cluster communication with worker nodes"

  egress {
    to_port   = 0
    protocol  = "-1"
    from_port = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name = "SAS k8s"
    Env  = "Development"
  }
}

resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  provider = aws.us-east-1

  type              = "ingress"
  to_port           = 443
  security_group_id = aws_security_group.cluster-sg.id
  protocol          = "tcp"
  from_port         = 443
  description       = "Allow workstation to communicate with the cluster API Server"

  cidr_blocks = [
    var.workstation-external-cidr,
  ]
}

resource "aws_eks_cluster" "default-cluster" {
  provider = aws.us-east-1

  role_arn = aws_iam_role.iam-cluster.arn
  name     = var.cluster-name

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]

  tags = {
    env      = "Staging"
    archUUID = "db83bcc0-696a-4f64-a6d5-fcc143caf3e2"
  }

  vpc_config {
    security_group_ids = [
      aws_security_group.cluster-sg.id,
    ]
    subnet_ids = [
      aws_subnet.subnet-1.id,
      aws_subnet.subnet-2.id,
    ]
  }
}

