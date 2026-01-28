FROM apache/airflow:2.8.1-python3.11

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем PySpark и дополнительные пакеты
USER airflow
RUN pip install --no-cache-dir \
    pyspark==3.5.1 \
    findspark==2.0.1 \
    pandas==2.1.4 \
    apache-airflow-providers-apache-spark==4.3.0

USER root
# Создаем симлинк для Java (для Spark)
RUN ln -sf /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17

USER airflow