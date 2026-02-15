#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Variables ---
PROJECT_NAME="ucapistran"
STATE_BUCKET="${PROJECT_NAME}-terraform-state"
LOCK_TABLE="${PROJECT_NAME}-state-lock"
REGION="us-east-1"

echo "🚀 Starting Infrastructure Bootstrap for: $PROJECT_NAME in $REGION"

# 1. Create S3 Bucket for Terraform State
if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" 2>/dev/null; then
    echo "⚠️  Bucket '$STATE_BUCKET' already exists. Skipping creation..."
else
    echo "🏗️  Creating S3 bucket..."
    aws s3 mb "s3://${STATE_BUCKET}" --region "${REGION}"
fi

# 2. Enable Bucket Versioning (Essential for State Recovery)
echo "🔧 Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
    --bucket "${STATE_BUCKET}" \
    --region "${REGION}" \
    --versioning-configuration Status=Enabled

# 3. Create DynamoDB Table for State Locking
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" 2>/dev/null; then
    echo "⚠️  Table '$LOCK_TABLE' already exists. Skipping creation..."
else
    echo "🏗️  Creating DynamoDB table..."
    aws dynamodb create-table \
        --table-name "${LOCK_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "${REGION}"
fi

echo "✅ Bootstrap completed successfully in $REGION."
echo "------------------------------------------------"
echo "Bucket: $STATE_BUCKET"
echo "Table:  $LOCK_TABLE"