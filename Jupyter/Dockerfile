FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    curl \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://archive.apache.org/dist/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz -C /opt/ && \
    mv /opt/spark-3.5.1-bin-hadoop3 /opt/spark && \
    rm spark-3.5.1-bin-hadoop3.tgz

RUN pip install --no-cache-dir \
    jupyterlab==4.0.11 \
    findspark==2.0.1 \
    pandas==2.1.4 \
    pyspark==3.5.1 \
    ipywidgets==8.1.2

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
    chown -R ${USER_UID}:${USER_GID} /etc/jupyter

RUN echo "spark.eventLog.enabled true" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.eventLog.dir /opt/spark/spark-events" >> /opt/spark/conf/spark-defaults.conf && \
    echo "spark.history.fs.logDirectory /opt/spark/spark-events" >> /opt/spark/conf/spark-defaults.conf && \
    mkdir -p /opt/spark/spark-events && \
    chown -R ${USER_UID}:${USER_GID} /opt/spark/spark-events

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN mkdir -p /home/${USERNAME}/notebooks

EXPOSE 8888 4040 18080

COPY ./Jupyter/entrypoint.sh /entrypoint.sh
USER root
RUN chmod +x /entrypoint.sh
USER ${USERNAME}

ENTRYPOINT ["/entrypoint.sh"]