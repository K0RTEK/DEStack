FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    curl \
    wget \
    git \
    vim \
    net-tools \
    iputils-ping \
    dnsutils \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN JAVA_REAL=$(dirname $(dirname $(readlink -f $(which java)))) && \
    mkdir -p /usr/lib/jvm && \
    ln -sf "$JAVA_REAL" /usr/lib/jvm/java-17-openjdk

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

RUN wget https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz -C /opt/ && \
    mv /opt/spark-3.5.1-bin-hadoop3 /opt/spark && \
    rm spark-3.5.1-bin-hadoop3.tgz

RUN wget https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.1/spark-sql-kafka-0-10_2.12-3.5.1.jar
RUN wget https://repo1.maven.org/maven2/org/apache/kafka/kafka-clients/3.5.1/kafka-clients-3.5.1.jar
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar \
RUN wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

RUN pip install --no-cache-dir \
    jupyterlab==4.0.11 \
    findspark==2.0.1 \
    pandas==2.1.4 \
    pyspark==3.5.1 \
    ipywidgets==8.1.2 \
    kafka-python==2.0.2 \
    confluent-kafka==2.3.0 \
    minio==7.2.3 \
    boto3 \
    s3fs==2023.10.0 \
    pyarrow==15.0.0 \
    fastparquet==2023.10.1 \
    matplotlib==3.8.2 \
    seaborn==0.13.0 \
    numpy==1.26.2 \
    scipy==1.11.4 \
    scikit-learn==1.3.2 \
    python-dotenv==1.0.0 \
    ipython==8.17.2 \
    notebook_shim==0.2.3 \
    psycopg2-binary \
    sqlalchemy \
    sqlalchemy-redshift

ARG USERNAME=sparkuser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    mkdir -p /opt/spark/work-dir && \
    chown -R ${USER_UID}:${USER_GID} /opt/spark/work-dir

RUN mkdir -p /etc/jupyter && \
    echo "c.ServerApp.token = ''" > /etc/jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.password = ''" >> /etc/jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /etc/jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /etc/jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_root = False" >> /etc/jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /etc/jupyter/jupyter_server_config.py && \
    chown -R ${USER_UID}:${USER_GID} /etc/jupyter

RUN echo "spark.eventLog.enabled true" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.eventLog.dir /opt/spark/spark-events" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.history.fs.logDirectory /opt/spark/spark-events" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.driver.memory 2g" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.executor.memory 2g" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.sql.repl.eagerEval.enabled true" >> /opt/spark/conf/spark-defaults.conf && \
    mkdir -p /opt/spark/spark-events && \
    chown -R ${USER_UID}:${USER_GID} /opt/spark/spark-events

ENV SPARK_HOME=/opt/spark
ENV PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
ENV PATH=$SPARK_HOME/bin:$PATH
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN mkdir -p /home/${USERNAME}/notebooks && \
    mkdir -p /home/${USERNAME}/data && \
    mkdir -p /home/${USERNAME}/.local/share/jupyter && \
    mkdir -p /home/${USERNAME}/.ipython/profile_default/startup

RUN echo "import findspark" > /home/${USERNAME}/.ipython/profile_default/startup/00-spark-init.py && \
    echo "findspark.init()" >> /home/${USERNAME}/.ipython/profile_default/startup/00-spark-init.py && \
    echo "print('Spark initialized automatically')" >> /home/${USERNAME}/.ipython/profile_default/startup/00-spark-init.py

EXPOSE 8888 4040 18080

COPY entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER ${USERNAME}

ENTRYPOINT ["/entrypoint.sh"]