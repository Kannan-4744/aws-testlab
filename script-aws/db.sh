#!/bin/bash

set -e

REGION="ap-south-1"

DB_IDENTIFIER="myapp-db"
DB_NAME="myapp"
DB_USER="admin"
DB_PASSWORD="MySecurePass123"   # 🔴 change this

VPC_ID="vpc-024adad3a973f5f79"

# ✅ FIXED: Using 2 AZs (1a + 1b)
SUBNET_IDS=("subnet-013c7e6001b06f572" "subnet-0726bcf955b60eca1")

echo "Creating RDS setup in $REGION..."

# =========================
# 1. CREATE DB SUBNET GROUP
# =========================
echo "Creating DB Subnet Group..."

aws rds create-db-subnet-group \
  --db-subnet-group-name my-db-subnet-group \
  --db-subnet-group-description "RDS subnet group" \
  --subnet-ids ${SUBNET_IDS[@]} \
  --region $REGION || echo "Subnet group may already exist"

# =========================
# 2. CREATE SECURITY GROUP
# =========================
echo "Creating Security Group..."

SG_ID=$(aws ec2 create-security-group \
  --group-name rds-sg \
  --description "RDS security group" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' \
  --output text)

echo "RDS SG: $SG_ID"

# Allow MySQL access from VPC
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3306 \
  --cidr 10.0.0.0/16 \
  --region $REGION || echo "Rule may already exist"

# =========================
# 3. CREATE RDS INSTANCE
# =========================
echo "Creating RDS instance..."

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

# =========================
# 4. WAIT FOR RDS
# =========================
echo "⏳ Waiting for RDS to become available (10–15 mins)..."

aws rds wait db-instance-available \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $REGION

# =========================
# 5. GET ENDPOINT
# =========================
ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --region $REGION \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "✅ RDS CREATED SUCCESSFULLY"
echo "-----------------------------------"
echo "Endpoint: $ENDPOINT"
echo "DB Name: $DB_NAME"
echo "User: $DB_USER"
echo "-----------------------------------"
