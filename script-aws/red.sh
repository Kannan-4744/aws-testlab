#!/bin/bash

set -e

REGION="ap-south-1"
DB_IDENTIFIER="myapp-db"
DB_NAME="myapp"
DB_USER="admin"
DB_PASSWORD="MySecurePass123"   # 🔴 change this

VPC_ID="vpc-024adad3a973f5f79"
SUBNET_IDS=("subnet-013c7e6001b06f572" "subnet-0554d9ecd89864fc9")

echo "Creating RDS setup..."

# =========================
# 1. CREATE DB SUBNET GROUP
# =========================
aws rds create-db-subnet-group \
  --db-subnet-group-name my-db-subnet-group \
  --db-subnet-group-description "RDS subnet group" \
  --subnet-ids ${SUBNET_IDS[@]} \
  --region $REGION

# =========================
# 2. CREATE SECURITY GROUP
# =========================
SG_ID=$(aws ec2 create-security-group \
  --group-name rds-sg \
  --description "RDS security group" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

echo "RDS SG: $SG_ID"

# Allow MySQL access (3306) from VPC
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3306 \
  --cidr 10.0.0.0/16 \
  --region $REGION

# =========================
# 3. CREATE RDS INSTANCE
# =========================
aws rds create-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --allocated-storage 20 \
  --master-username $DB_USER \
  --master-user-password $DB_PASSWORD \
  --db-name $DB_NAME \
  --vpc-security-group-ids $SG_ID \
  --db-subnet-group-name my-db-subnet-group \
  --backup-retention-period 7 \
  --no-publicly-accessible \
  --region $REGION

echo "⏳ Waiting for RDS to be available..."
aws rds wait db-instance-available \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $REGION

# =========================
# 4. GET ENDPOINT
# =========================
ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "✅ RDS READY"
echo "Endpoint: $ENDPOINT"
