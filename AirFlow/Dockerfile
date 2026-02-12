FROM apache/airflow:2.8.1-python3.11

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    wget \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

RUN pip install --no-cache-dir \
    pyspark==3.5.1 \
    findspark==2.0.1 \
    pandas==2.1.4 \
    apache-airflow-providers-apache-spark==4.3.0 \
    apache-airflow-providers-apache-kafka==1.2.0 \
    kafka-python==2.0.2 \
    confluent-kafka==2.3.0 \
    apache-airflow-providers-amazon==8.13.0 \
    minio==7.2.3 \
    boto3==1.34.0 \
    botocore==1.34.0 \
    python-dotenv==1.0.0 \
    pyarrow==15.0.0 \
    fastparquet==2023.10.1 \
    psycopg2-binary \
    sqlalchemy \
    sqlalchemy-redshift

USER root

RUN ln -sf /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17

ENV JAVA_HOME=/usr/lib/jvm/java-17
ENV PATH=$JAVA_HOME/bin:$PATH

USER airflow