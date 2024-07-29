FROM apache/hive:4.0.0-beta-1

USER root
RUN apt update && apt install curl -y

RUN curl -L --output postgresql-42.4.0.jar https://jdbc.postgresql.org/download/postgresql-42.4.0.jar && \
    curl -L --output hadoop-aws-3.3.1.jar  https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar && \
    curl -L --output aws-java-sdk-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.12.609/aws-java-sdk-1.12.609.jar && \
    curl -L --output hadoop-common-3.3.6.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/3.3.6/hadoop-common-3.3.6.jar && \
    curl -L --output aws-java-sdk-s3-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.12.609/aws-java-sdk-s3-1.12.609.jar && \
    curl -L --output aws-java-sdk-core-1.12.609.jar https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.12.609/aws-java-sdk-core-1.12.609.jar && \
    curl -L --output delta-spark_2.12-3.0.0.jar https://repo1.maven.org/maven2/io/delta/delta-spark_2.12/3.0.0/delta-spark_2.12-3.0.0.jar && \
    curl -L --output delta-storage-3.0.0.jar  https://repo1.maven.org/maven2/io/delta/delta-storage/3.0.0/delta-storage-3.0.0.jar && \
    curl -L --output scala-library-2.12.4.jar https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.4/scala-library-2.12.4.jar && \
    cp scala-library-2.12.4.jar /opt/hive/lib/ && \
    cp delta-spark_2.12-3.0.0.jar /opt/hive/lib/ && \
    cp delta-storage-3.0.0.jar /opt/hive/lib/ && \
    cp hadoop-aws-3.3.1.jar /opt/hadoop/share/hadoop/common/lib/ && \
    cp postgresql-42.4.0.jar /opt/hive/lib/ && \
    cp aws-java-sdk-1.12.609.jar /opt/hive/lib/ && \
    cp hadoop-common-3.3.6.jar /opt/hadoop/share/hadoop/common/lib/ && \
    cp aws-java-sdk-s3-1.12.609.jar /opt/hive/lib/ && \
    cp aws-java-sdk-core-1.12.609.jar /opt/hive/lib/ 


RUN rm -rf postgresql-42.4.0.jar hadoop-aws-3.3.1.jar aws-java-sdk-1.12.609.jar hadoop-common-3.3.6.jar aws-java-sdk-s3-1.12.609.jar aws-java-sdk-core-1.12.609.jar

COPY  hive-site.xml /opt/hive/conf/hive-site.xml
COPY entrypoint.sh /opt/hive/entrypoint.sh
RUN chmod +x /opt/hive/entrypoint.sh
ENTRYPOINT ["/opt/hive/entrypoint.sh"]

USER hive





