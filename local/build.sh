#!/bin/bash

docker buildx build \
    --platform linux/amd64 \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/dev-hive-metastore:v1 \
    . --push

aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.region.amazonaws.com

docker buildx build \
    --platform linux/amd64 \
    -t ${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/prod-hive:latest \
    . --push
