# Песочница Data Engineer

---

## О проекте

Проект создан для практики полного цикла работы с данными и изучения актуальных инструментов,
которые ежедневно используются в работе Data Engineer'ов. Аналогичное решение уже
существует — [data-forge](https://github.com/fortiql/data-forge),
но из-за использования неофициальных Docker-образов без жёсткого версионирования зависимостей его актуальность
со временем снизилась. Эта песочница решает эту проблему: все образы официальные, версии зафиксированы,
окружение воспроизводимо.

---

## Стек инструментов

**Уже настроено:**

- **Apache Airflow** — оркестрация и планирование задач
- **PostgreSQL** — реляционная СУБД (метаданные Airflow, приложение, метаданные Superset)
- **pgAdmin / Adminer** — веб-интерфейсы для работы с PostgreSQL
- **Jupyter + PySpark** — интерактивная аналитика и обработка данных
- **Apache Kafka + Zookeeper** — потоковая обработка событий
- **Kafka UI** — визуализация топиков и сообщений
- **Debezium** — CDC-платформа для потокового копирования изменений из PostgreSQL в Kafka
- **ClickHouse** — колоночная СУБД для аналитики
- **ClickHouse UI (CH-UI)** — веб-интерфейс для работы с ClickHouse
- **Apache Superset** — BI-платформа для визуализации и дашбордов
- **Grafana** — визуализация метрик и дашборды
- **dbt** — трансформация данных по принципу «трансформация как код» (тесты, документация, зависимости моделей)
- **MongoDB** — документная СУБД
- **MinIO** — S3-совместимое хранилище объектов

---

## Структура проекта

Каждый инструмент вынесен в отдельную директорию внутри `services/` со своим `Dockerfile`.
Версии инструментов зафиксированы прямо в `FROM`, изменение версии — это правка одного `Dockerfile`.
`docker-compose.yaml` собирает все сервисы из этих контекстов (директивы `build`), у сервисов нет тегов `:latest`.

```
.
├── docker-compose.yaml      # описание всех сервисов
├── start-infra.sh           # пошаговый запуск окружения
└── services/
    ├── adminer/             # веб-клиент БД
    ├── airflow/             # оркестратор (+ DAGs, логи)
    ├── clickhouse/          # колоночная СУБД
    ├── clickhouse-ui/       # CH-UI
    ├── dbt/                 # dbt-проект (profiles.yml, models)
    ├── debezium/            # Kafka Connect + CDC-коннекторы
    ├── grafana/             # визуализация метрик и дашборды
    ├── jupyter/             # JupyterLab + PySpark
    ├── kafka/               # брокер Kafka
    ├── kafka-ui/            # Kafka UI
    ├── minio/               # S3-совместимое хранилище
    ├── minio-client/        # mc (инициализация бакетов)
    ├── mongodb/             # документная СУБД
    ├── pgadmin/             # веб-интерфейс PostgreSQL (+ servers.json)
    ├── postgres/            # PostgreSQL (Dockerfile 16.15, Dockerfile.airflow 13.23, init.sql)
    ├── redis/               # кэш/broker для Superset
    ├── superset/            # BI-платформа (+ superset_config.py)
    └── zookeeper/           # координация Kafka
```

Рабочие данные и конфиги лежат рядом с `Dockerfile` инструмента
(например, `services/airflow/dags`, `services/postgres/init.sql`, `services/jupyter/notebooks`,
`services/superset/superset_config.py`, `services/pgadmin/servers.json`).

---

## Быстрый старт

```bash
./start-infra.sh
```

Скрипт последовательно: останавливает предыдущий запуск, создаёт директории, собирает образы
(`docker-compose build --pull`), затем поэтапно поднимает сервисы, проверяет их доступность
и печатает список ссылок и доступов.

Ручной запуск:

```bash
docker compose build --pull   # собрать образы из services/
docker compose up -d          # поднять всё
docker compose ps             # статус
docker compose down           # остановить (без -v данные сохранятся)
docker compose down -v        # остановить и удалить тома
```

---

## Доступы и порты

### Основные сервисы

| Сервис | URL / порт | Логин / пароль |
|---|---|---|
| Airflow | http://localhost:8080 | `admin` / `admin` |
| JupyterLab | http://localhost:8888 | без пароля |
| Spark UI (Jupyter) | http://localhost:4040, http://localhost:18080 | — |
| Superset | http://localhost:8088 | `admin` / `admin` |

### Мониторинг и администрирование

| Сервис | URL / порт | Логин / пароль |
|---|---|---|
| Kafka UI | http://localhost:8081 | — |
| Debezium Connect | http://localhost:8083 | — |
| MinIO Console | http://localhost:9001 | `minioadmin` / `minioadmin` |
| pgAdmin | http://localhost:5050 | `admin@example.com` / `admin` |
| Adminer | http://localhost:8082 | данные указываются при подключении |
| ClickHouse UI (CH-UI) | http://localhost:3488 | `clickhouse` / `clickhouse` |
| Grafana | http://localhost:3000 | `admin` / `admin` |

### Базы данных и хранилища

| Сервис | Хост:порт | Доступ |
|---|---|---|
| PostgreSQL (Airflow) | `localhost:5432` | БД `airflow`, `airflow` / `airflow` |
| PostgreSQL (Приложения) | `localhost:5433` | БД `app_db`, `app_user` / `app_password` |
| ClickHouse (HTTP) | `localhost:8123` | БД `default`, `clickhouse` / `clickhouse` |
| ClickHouse (native) | `localhost:9009` | — |
| MongoDB | `localhost:27017` | `kirill` / `5567` |
| MinIO API | http://localhost:9000 | `minioadmin` / `minioadmin` |

### Kafka и Zookeeper

| Что | Адрес |
|---|---|
| Kafka (внутри сети Docker) | `kafka:9092` |
| Kafka (с хоста) | `localhost:29092` |
| Zookeeper | `localhost:2181` |

Бакеты MinIO: `airflow-data` (логи Airflow), `spark-data` (данные Spark), `kafka-data` (данные Kafka).

---

## Зафиксированные версии

Версии базовых образов указаны в `services/<tool>/Dockerfile`:

| Инструмент | Образ |
|---|---|
| Airflow | `apache/airflow:2.8.1-python3.11` |
| Jupyter | `ubuntu:22.04` + Spark `3.5.1` |
| PostgreSQL (приложение) | `postgres:16.15-alpine` |
| PostgreSQL (Airflow) | `postgres:13.23-alpine` |
| pgAdmin | `dpage/pgadmin4:8.10` |
| Adminer | `adminer:6.1.1` |
| MongoDB | `mongo:7.0.43` |
| Zookeeper | `zookeeper:3.9.6` |
| Kafka | `confluentinc/cp-kafka:7.3.0` |
| Kafka UI | `provectuslabs/kafka-ui:v0.7.2` |
| Debezium | `debezium/connect:2.5.4.Final` |
| MinIO | `bitnamilegacy/minio:2025.7.23-debian-12-r5` |
| MinIO client | `bitnamilegacy/minio-client:2025.7.21-debian-12-r3` |
| ClickHouse | `clickhouse/clickhouse-server:25.8.33.6` |
| ClickHouse UI | `ghcr.io/caioricciuti/ch-ui:v2.16.0` |
| Grafana | `grafana/grafana:13.2.3` |
| dbt | `python:3.12.15-slim-bookworm` + `dbt-core 1.10.9`, `dbt-postgres 1.10.2`, `dbt-clickhouse 1.10.3` |
| Superset | `apache/superset:5.0.0` (+ `psycopg2-binary`) |
| Redis (Superset) | `redis:7.4.11-alpine` |

> MinIO: официальные образы `minio/minio` и `minio/mc` удалены из публичных реестров,
> поэтому используются архивные сборки Bitnami с жёсткой привязкой версий.

```bash
# Обновить версию инструмента:
# 1) поправить FROM в services/<tool>/Dockerfile
# 2) docker compose build <service>
```

---

## Замечания

- Если сборка падает с `429 Too Many Requests` — это анонимный лимит Docker Hub.
  Выполните `docker login` и повторите `docker compose build --pull`.
- Порт `9009` для ClickHouse native выбран потому, что `9000` занят MinIO.
- Данные хранятся в именованных томах Docker; `start-infra.sh` использует `down -v`,
  то есть при запуске скрипта данные удаляются.
- **dbt** работает как долгоживущий контейнер, команды выполняются через `exec`:
  ```bash
  docker compose exec dbt dbt debug                 # проверка соединения (target: postgres)
  docker compose exec dbt dbt run                   # запуск моделей
  docker compose exec dbt dbt test                  # тесты
  docker compose exec dbt dbt run --target clickhouse   # запуск на ClickHouse
  ```
  Проект лежит в `services/dbt/` (монтируется в `/dbt`): `dbt_project.yml`, `profiles.yml`, `models/`.
  Соединения настраиваются через env-переменные `DBT_PG_*` и `DBT_CH_*` в `services/dbt/profiles.yml`.
