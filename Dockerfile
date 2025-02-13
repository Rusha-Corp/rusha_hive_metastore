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


# ------------------------------
# Stage 2: Build Hive Docker Image
# ------------------------------
FROM openjdk:17-jdk-slim AS runtime

RUN apt update && apt install -y wget

ARG HIVE_VERSION=4.0.0
ARG HIVE_HOME=/opt/hive
ARG HADOOP_HOME=/opt/hadoop
ARG HADOOP_VERSION=3.3.1
ARG TEZ_VERSION=0.10.4
ARG TEZ_HOME=/opt/tez

ENV HIVE_VERSION=${HIVE_VERSION}
ENV HIVE_HOME=${HIVE_HOME}
ENV HADOOP_HOME=${HADOOP_HOME}
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV TEZ_VERSION=${TEZ_VERSION}
ENV TEZ_HOME=${TEZ_HOME}

# Install dependencies
RUN set -ex; \
    apt-get update; \
    apt-get -y install procps netcat; \
    rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN set -eux; \
    HADOOP_TGZ_URL=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz; \
    HADOOP_TMP="$(mktemp -d)" && cd "$HADOOP_TMP"; \
    wget -q -O hadoop.tgz "$HADOOP_TGZ_URL"; \
    tar -xzf hadoop.tgz -C /opt; \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME}; \
    rm -rf "$HADOOP_TMP"

# Download and install Tez
RUN set -eux; \
    TEZ_TGZ_URL=https://archive.apache.org/dist/tez/${TEZ_VERSION}/apache-tez-${TEZ_VERSION}-bin.tar.gz; \
    TEZ_TMP="$(mktemp -d)" && cd "$TEZ_TMP"; \
    wget -q -O tez.tgz "$TEZ_TGZ_URL"; \
    tar -xzf tez.tgz -C /opt; \
    mv /opt/apache-tez-${TEZ_VERSION}-bin ${TEZ_HOME}; \
    rm -rf "$TEZ_TMP"

# Download and verify Apache Hive
RUN set -eux; \
    HIVE_TGZ_URL=https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz; \
    HIVE_TGZ_ASC_URL=${HIVE_TGZ_URL}.asc; \
    \
    # Create temporary working directory
    HIVE_TMP="$(mktemp -d)" && cd "$HIVE_TMP"; \
    \
    # Download Hive and signature
    wget -q -O hive.tgz "$HIVE_TGZ_URL"; \
    wget -q -O hive.tgz.asc "$HIVE_TGZ_ASC_URL"; \
    \
    # Extract Hive and clean up
    tar -xzf hive.tgz -C /opt; \
    mv /opt/apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME}; \
    rm -rf "$HIVE_TMP"

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ARG USER=hive
ARG UID=1000
ENV USER=$USER
ENV UID=$UID

RUN adduser --no-create-home --disabled-login --gecos "" --uid $UID $USER && \
    chown $USER /opt/tez && \
    chown $USER /opt/hive && \
    chown $USER /opt/hadoop && \
    chown $USER /opt/hive/conf && \
    mkdir -p /opt/hive/data/warehouse && \
    chown $USER /opt/hive/data/warehouse && \
    mkdir -p /home/$USER/.beeline && \
    chown $USER /home/$USER/.beeline 

# Add these lines after creating the hive user and before switching to it
RUN mkdir -p /var/log/hive && \
    touch /var/log/hive/hive.log && \
    chown -R $USER:$USER /var/log/hive && \
    chmod 755 /var/log/hive && \
    chmod 644 /var/log/hive/hive.log

USER $USER
WORKDIR /opt/hive

COPY conf/hive-site.xml $HIVE_HOME/conf/

COPY --from=build /app/target/lib/* $HIVE_HOME/lib/
ENV PATH=$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH

EXPOSE 10000 10002 9083
ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]



