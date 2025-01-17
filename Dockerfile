# ------------------------------
# Stage 1: Build Fat JAR with SBT
# ------------------------------
FROM openjdk:17-jdk-slim AS build

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

# Install SBT
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add
RUN apt-get update
RUN apt-get install sbt -y

# Set working directory
WORKDIR /app

# Copy project files and build the Fat JAR
COPY . /app
RUN sbt assembly

FROM apache/hive:4.0.0 AS hive

USER root
RUN apt update
RUN apt install curl -y
ARG HIVE_VERSION=4.0.0
ARG HIVE_HOME=/opt/hive

COPY --from=build /app/target/lib/* $HIVE_HOME/lib/

