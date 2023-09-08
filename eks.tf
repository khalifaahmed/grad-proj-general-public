# Create IAM Role for the master node
resource "aws_iam_role" "eks_master_role" {
  name = "eks-master-role"

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
}

# Associate the proper IAM Policies to IAM Role of the master node
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_master_role.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_master_role.name
}





# IAM Role for EKS Node Group 
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "eks-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Associate the proper IAM policies to the node group IAM role
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodegroup_role.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodegroup_role.name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodegroup_role.name
}




# Create AWS EKS Cluster 
resource "aws_eks_cluster" "eks_cluster" {
  # the name of the cluster 
  name     = "grad-proj-eks-cluster"
  # attach the master IAM role we created previously to the cluster 
  role_arn = aws_iam_role.eks_master_role.arn
  # determine the wanted version of the cluster 
  version = "1.26"

  vpc_config {
    # provide the cluster with a public subnet in each avalaibility zone in the region
    subnet_ids = [for i in range(0, length(data.aws_availability_zones.available.names), 1) : aws_subnet.public[i].id]
    # preventing access the cluster through the node group instances
    endpoint_private_access = false
    # Allowing access the cluster through public access (our labtop)
    endpoint_public_access  = true
    # Allowing only our ip to access the cluster through kubectl 
    # but here we make it any ip, as our ip is not static
    public_access_cidrs     = ["0.0.0.0/0"]   
  }
  
  # determine the ip range of the services created inside the cluster
  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
  }
  
  # Enable EKS Cluster Control Plane Logging (in cloudwatch logs)
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}






# Create AWS EKS Node Group - Public
resource "aws_eks_node_group" "eks_ng_public" {
  # Attach the node group to our eks cluster 
  cluster_name    = aws_eks_cluster.eks_cluster.name

  # name of the node group
  node_group_name = "grad-proj-eks-ng-public"
  # attach the eks_nodegroup IAM role we created to the node group
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  # provide the node group with a public subnet in each avalaibility zone in the region
  subnet_ids      = [for i in range(0, length(data.aws_availability_zones.available.names), 1) : aws_subnet.public[i].id]   

  # determine the specifications of each ec2 instance in the node group   
  ami_type = "AL2_x86_64"  
  capacity_type = "ON_DEMAND"
  disk_size = 10
  instance_types = ["t2.micro"]
  
  # Allowing ssh access to the node group instances through our ssh-key
  remote_access {
    ec2_ssh_key = var.key
  }

  # creating an autoscaling group with the desired number of ec2 instances
  scaling_config {
    desired_size = 7
    min_size     = 5    
    max_size     = 9
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1    
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ] 

  tags = {
    Name = "Public-Node-Group"
  }
}
