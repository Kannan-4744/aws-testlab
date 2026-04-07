#!/bin/bash

set -e

# =========================
# CONFIG
# =========================
REGION="ap-south-1"
VPC_CIDR="10.0.0.0/16"

echo "Using region: $REGION"

# =========================
# GET AZs (dynamic)
# =========================
AZ1=$(aws ec2 describe-availability-zones \
  --region $REGION \
  --query 'AvailabilityZones[0].ZoneName' \
  --output text)

AZ2=$(aws ec2 describe-availability-zones \
  --region $REGION \
  --query 'AvailabilityZones[1].ZoneName' \
  --output text)

echo "AZ1=$AZ1"
echo "AZ2=$AZ2"

# =========================
# 1. CREATE VPC
# =========================
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC_ID=$VPC_ID"

# Enable DNS
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support "{\"Value\":true}" \
  --region $REGION

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames "{\"Value\":true}" \
  --region $REGION

# Tag VPC
aws ec2 create-tags \
  --resources $VPC_ID \
  --tags Key=Name,Value=my-eks-vpc \
  --region $REGION

# =========================
# 2. INTERNET GATEWAY
# =========================
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $REGION

echo "IGW_ID=$IGW_ID"

# =========================
# 3. SUBNETS
# =========================
PUB_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone $AZ1 \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

PUB_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone $AZ2 \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

PRIV_SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone $AZ1 \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

PRIV_SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone $AZ2 \
  --region $REGION \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Subnets created"

# Enable public IP
aws ec2 modify-subnet-attribute \
  --subnet-id $PUB_SUBNET_1 \
  --map-public-ip-on-launch \
  --region $REGION

aws ec2 modify-subnet-attribute \
  --subnet-id $PUB_SUBNET_2 \
  --map-public-ip-on-launch \
  --region $REGION

# =========================
# 4. PUBLIC ROUTE TABLE
# =========================
PUB_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PUB_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $REGION

aws ec2 associate-route-table \
  --subnet-id $PUB_SUBNET_1 \
  --route-table-id $PUB_RT \
  --region $REGION

aws ec2 associate-route-table \
  --subnet-id $PUB_SUBNET_2 \
  --route-table-id $PUB_RT \
  --region $REGION

# =========================
# 5. NAT GATEWAY
# =========================
EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc \
  --region $REGION \
  --query 'AllocationId' \
  --output text)

NAT_GW=$(aws ec2 create-nat-gateway \
  --subnet-id $PUB_SUBNET_1 \
  --allocation-id $EIP_ALLOC \
  --region $REGION \
  --query 'NatGateway.NatGatewayId' \
  --output text)

echo "Waiting for NAT Gateway..."
sleep 60

# =========================
# 6. PRIVATE ROUTE TABLE
# =========================
PRIV_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' \
  --output text)

aws ec2 create-route \
  --route-table-id $PRIV_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW \
  --region $REGION

aws ec2 associate-route-table \
  --subnet-id $PRIV_SUBNET_1 \
  --route-table-id $PRIV_RT \
  --region $REGION

aws ec2 associate-route-table \
  --subnet-id $PRIV_SUBNET_2 \
  --route-table-id $PRIV_RT \
  --region $REGION

# =========================
# 7. TAG SUBNETS FOR EKS
# =========================
CLUSTER_NAME="my-eks-cluster"

# Public
aws ec2 create-tags --resources $PUB_SUBNET_1 $PUB_SUBNET_2 \
  --tags Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared \
         Key=kubernetes.io/role/elb,Value=1 \
  --region $REGION

# Private
aws ec2 create-tags --resources $PRIV_SUBNET_1 $PRIV_SUBNET_2 \
  --tags Key=kubernetes.io/cluster/$CLUSTER_NAME,Value=shared \
         Key=kubernetes.io/role/internal-elb,Value=1 \
  --region $REGION

echo "✅ VPC setup complete"
echo "VPC_ID=$VPC_ID"
