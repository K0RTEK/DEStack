FROM python:3.12.15-slim-bookworm

RUN pip install --no-cache-dir \
    dbt-core==1.10.9 \
    dbt-postgres==1.10.2 \
    dbt-clickhouse==1.10.3

ENV DBT_PROFILES_DIR=/dbt
WORKDIR /dbt

CMD ["sleep", "infinity"]