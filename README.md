# Hive Metastore Dockerfile Documentation

## Purpose
This Dockerfile sets up a Hive Metastore container based on the Apache Hive image (version 4.0.0-beta-1). It includes the necessary dependencies and configurations for connecting to PostgreSQL and AWS S3.

### Base Image
```dockerfile
FROM apache/hive:4.0.0-beta-1
```

### Steps

#### 1. Install Curl
```dockerfile
USER root
RUN apt update && apt install curl -y
```
Install Curl for downloading dependencies.

#### 2. Download and Configure Dependencies
```dockerfile
RUN curl -L --output postgresql-42.4.0.jar https://jdbc.postgresql.org/download/postgresql-42.4.0.jar && \
    curl -L --output hadoop-aws-3.3.1.jar  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar && \
    curl -L --output aws-java-sdk-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.12.609/aws-java-sdk-1.12.609.jar && \
    curl -L --output hadoop-common-3.3.6.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.6/hadoop-common-3.3.6.jar && \
    curl -L --output aws-java-sdk-s3-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.12.609/aws-java-sdk-s3-1.12.609.jar && \
    curl -L --output aws-java-sdk-core-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.12.609/aws-java-sdk-core-1.12.609.jar && \
    cp hadoop-aws-3.3.1.jar /opt/hadoop/share/hadoop/common/lib/ && \
    cp postgresql-42.4.0.jar /opt/hive/lib/ && \
    cp aws-java-sdk-1.12.609.jar /opt/hive/lib/ && \
    cp hadoop-common-3.3.6.jar /opt/hadoop/share/hadoop/common/lib/ && \
    cp aws-java-sdk-s3-1.12.609.jar /opt/hive/lib/ && \
    cp aws-java-sdk-core-1.12.609.jar /opt/hive/lib/ && \
    rm -rf postgresql-42.4.0.jar hadoop-aws-3.3.1.jar aws-java-sdk-1.12.609.jar hadoop-common-3.3.6.jar aws-java-sdk-s3-1.12.609.jar aws-java-sdk-core-1.12.609.jar
```
Download PostgreSQL and AWS dependencies, and copy them to the appropriate directories.

#### 3. Copy Hive Configuration
```dockerfile
COPY  hive-site.xml /opt/hive/conf/hive-site.xml
```
Copy the provided `hive-site.xml` configuration file to the Hive configuration directory.

### Hive Site Configuration

The `hive-site.xml` configuration file includes various properties to customize the Hive Metastore.

```xml
<!-- hive-site.xml -->
<configuration>
    <!-- ... Other properties ... -->

    <!-- Hive Metastore Warehouse Directory -->
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>s3a://warehouse/</value>
    </property>

    <!-- AWS S3 Configuration -->
    <property>
        <name>fs.s3a.aws.credentials.provider</name>
        <value>org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider</value>
    </property>
    <property>
        <name>fs.s3a.access.key</name>
        <value>54f4baeeca9acecea770c9d6d192f43a</value>
    </property>
    <property>
        <name>fs.s3a.secret.key</name>
        <value>35787db2cfc56c70ecc413b1410febff</value>
    </property>
    <property>
        <name>fs.s3a.endpoint</name>
        <value>https://eu2.contabostorage.com</value>
    </property>
    <!-- ... Other S3 properties ... -->

    <!-- PostgreSQL Metastore Configuration -->
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.postgresql.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://postgres:5432/metastore_db</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>password</value>
    </property>
    <!-- ... Other PostgreSQL properties ... -->

    <!-- Hive Metastore URI -->
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://hive-metastore:9083</value>
    </property>

    <!-- ... Other properties ... -->
</configuration>
```

This configuration includes settings for AWS S3, PostgreSQL, Hive Metastore URI, and other Hive properties.

### Note
Ensure that the `hive-site.xml` configuration file aligns with your specific requirements and AWS credentials. Adjustments may be necessary based on your environment and setup.