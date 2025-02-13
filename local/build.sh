#!/bin/bash

export $(grep -v '^#' .env | xargs)
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker buildx build \
    --platform linux/amd64 \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/prod/hive-metastore:latest \
    . --push