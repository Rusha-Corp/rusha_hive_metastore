#!/bin/bash

docker buildx build \
    --platform linux/amd64 \
    -t 217493348668.dkr.ecr.eu-west-2.amazonaws.com/dev-hive-metastore:v1 \
    . --push