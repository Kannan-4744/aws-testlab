#!/bin/bash

set -e

REGION="ap-south-1"
CLUSTER_NAME="my-eks-cluster"

SUBNET_IDS="subnet-0726bcf955b60eca1,subnet-01b017260f4bca21e,subnet-013c7e6001b06f572,subnet-0554d9ecd89864fc9"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating EKS cluster..."

# =========================
# 1. CREATE CLUSTER ROLE
# =========================
aws iam create-role \
  --role-name eksClusterRole \
  --assume-role-policy-document file://<(cat <<EOF
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
EOF
)

aws iam attach-role-policy \
  --role-name eksClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# =========================
# 2. CREATE EKS CLUSTER
# =========================
aws eks create-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --role-arn arn:aws:iam::$ACCOUNT_ID:role/eksClusterRole \
  --resources-vpc-config subnetIds=$SUBNET_IDS

echo "Waiting for cluster to become ACTIVE..."
aws eks wait cluster-active --name $CLUSTER_NAME --region $REGION

# =========================
# 3. CREATE NODE ROLE
# =========================
aws iam create-role \
  --role-name eksNodeRole \
  --assume-role-policy-document file://<(cat <<EOF
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
EOF
)

aws iam attach-role-policy \
  --role-name eksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name eksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam attach-role-policy \
  --role-name eksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

# =========================
# 4. CREATE NODE GROUP
# =========================
aws eks create-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name my-nodes \
  --subnets $SUBNET_IDS \
  --node-role arn:aws:iam::$ACCOUNT_ID:role/eksNodeRole \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --instance-types t3.medium \
  --region $REGION

echo "Waiting for node group..."
aws eks wait nodegroup-active \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name my-nodes \
  --region $REGION

# =========================
# 5. CONNECT TO CLUSTER
# =========================
aws eks update-kubeconfig \
  --region $REGION \
  --name $CLUSTER_NAME

kubectl get nodes

echo "✅ EKS CLUSTER READY 🚀"
