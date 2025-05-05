#!/bin/bash

# Retrieve DB URL from AWS SSM Parameter Store
API_URL=$(aws ssm get-parameter \
  --name /dor/tf/db-url \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# Retrieve DB user and password from AWS Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id rds!db-777ab260-d218-40d6-8bff-a5f247435ce3 \
  --query 'SecretString' \
  --output text)

# Extract the DB user and password from the JSON secret
DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)

# Remove any existing container
docker rm -f liordb-container || true

# Build the Docker image
echo "Building Docker image..."
docker build -t liordb-app .

# Run the Docker container with the environment variables
echo "Running the Docker container..."
docker run -d -p 3000:3000 \
  -e DB_URL="$API_URL" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  --name liordb-container \
  liordb-app

# Output the status
echo "App is running at http://localhost:3000"

