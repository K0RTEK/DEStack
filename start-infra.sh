#!/bin/bash

set -e

echo "=== Очистка предыдущих запусков ==="
docker-compose down -v

echo "=== Создание необходимых директорий ==="
mkdir -p ./postgres ./pgadmin ./Jupyter/spark-events

echo "=== Запуск базовых сервисов ==="
docker-compose up -d postgres-airflow minio zookeeper postgres-app

echo "Ожидание 30 секунд для базовых сервисов..."
sleep 30

echo "Проверка PostgreSQL для приложений..."
if docker-compose exec postgres-app pg_isready -U app_user -d app_db; then
    echo "✓ PostgreSQL приложений готов"
else
    echo "✗ PostgreSQL приложений не готов"
    docker-compose logs postgres-app --tail=20
    exit 1
fi

echo "Проверка PostgreSQL для Airflow..."
if docker-compose exec postgres-airflow pg_isready -U airflow -d airflow; then
    echo "✓ PostgreSQL Airflow готов"
else
    echo "✗ PostgreSQL Airflow не готов"
    docker-compose logs postgres-airflow --tail=20
    exit 1
fi

echo "Проверка Zookeeper..."
if echo ruok | nc localhost 2181 2>/dev/null | grep -q imok; then
    echo "✓ Zookeeper готов"
elif docker-compose ps zookeeper | grep -q "(healthy)"; then
    echo "✓ Zookeeper готов (healthcheck)"
else
    echo "✗ Zookeeper не готов"
    docker-compose logs zookeeper --tail=20
    # Пробуем запустить без строгой проверки
    echo "Продолжаем запуск..."
fi

echo "Запуск Kafka..."
docker-compose up -d kafka

echo "Ожидание 40 секунд для Kafka..."
sleep 40

echo "Проверка Kafka..."
if docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null; then
    echo "✓ Kafka готова"
    docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --create --topic test_topic --partitions 3 --replication-factor 1 2>/dev/null || true
    docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --create --topic sensor_data --partitions 2 --replication-factor 1 2>/dev/null || true
else
    echo "⚠️  Kafka не отвечает, проверяем альтернативным способом..."
    if docker-compose logs kafka --tail=10 | grep -q "started"; then
        echo "✓ Kafka запущена (по логам)"
    else
        echo "✗ Kafka не запустилась"
        docker-compose logs kafka --tail=30
        echo "Продолжаем запуск других сервисов..."
    fi
fi

echo "Запуск UI сервисов и утилит..."
docker-compose up -d kafka-ui createbuckets pgadmin adminer

echo "Ожидание 20 секунд для UI сервисов..."
sleep 20

echo "Запуск Airflow инициализации..."
docker-compose up -d airflow-init

echo "Ожидание 30 секунд для инициализации Airflow..."
sleep 30

echo "Проверка Airflow инициализации..."
if docker-compose logs airflow-init --tail=20 | grep -q "Пользователь admin создан"; then
    echo "✓ Airflow инициализирован"
else
    echo "⚠️  Airflow инициализация, проверяем лог..."
    docker-compose logs airflow-init --tail=10
fi

echo "Запуск основных сервисов Airflow и Jupyter..."
docker-compose up -d airflow-scheduler airflow-webserver pyspark-jupyter

echo "Ожидание 30 секунд для полного запуска..."
sleep 30

echo "=== Статус контейнеров ==="
docker-compose ps

echo ""
echo "=== Проверка доступности сервисов ==="

check_http_service() {
    local name=$1
    local url=$2
    local timeout=10

    if curl -f -s -o /dev/null --max-time $timeout "$url"; then
        echo "✓ $name доступен: $url"
        return 0
    else
        echo "⚠️  $name недоступен: $url"
        return 1
    fi
}

echo ""
echo "Проверка HTTP сервисов:"

check_http_service "MinIO Console" "http://localhost:9001/minio/health/live" || true
check_http_service "Airflow" "http://localhost:8080/health" || true
check_http_service "Kafka UI" "http://localhost:8081" || true
check_http_service "pgAdmin" "http://localhost:5050" || true
check_http_service "Adminer" "http://localhost:8082" || true

echo ""
echo "=== Ссылки для доступа ==="
echo ""
echo "📊 МОНИТОРИНГ И АДМИНИСТРИРОВАНИЕ:"
echo "  Kafka UI:        http://localhost:8081"
echo "  MinIO Console:   http://localhost:9001"
echo "     Логин: minioadmin"
echo "     Пароль: minioadmin"
echo "  pgAdmin:         http://localhost:5050"
echo "     Email: admin@example.com"
echo "     Пароль: admin"
echo "  Adminer:         http://localhost:8082"
echo "     (укажите данные при подключении)"
echo ""
echo "🚀 ОСНОВНЫЕ СЕРВИСЫ:"
echo "  Airflow:         http://localhost:8080"
echo "     Логин: admin"
echo "     Пароль: admin"
echo "  Jupyter:         http://localhost:8888"
echo "     (без пароля)"
echo ""
echo "🗄️  БАЗЫ ДАННЫХ:"
echo "  PostgreSQL (Airflow):    localhost:5432"
echo "     БД: airflow"
echo "     Пользователь: airflow"
echo "     Пароль: airflow"
echo "  PostgreSQL (Приложения): localhost:5433"
echo "     БД: app_db"
echo "     Пользователь: app_user"
echo "     Пароль: app_password"
echo ""
echo "📡 КАФКА И ZOOKEEPER:"
echo "  Kafka (внутри сети Docker):  kafka:9092"
echo "  Kafka (с хоста):             localhost:29092"
echo "  Zookeeper:                   localhost:2181"
echo ""
echo "💾 ХРАНИЛИЩА:"
echo "  MinIO API:                   http://localhost:9000"
echo "  Buckets:"
echo "    - airflow-data (для логов Airflow)"
echo "    - spark-data (для данных Spark)"
echo "    - kafka-data (для данных Kafka)"
echo ""
echo "=== Полезные команды ==="
echo "Просмотр логов:           docker-compose logs -f [service]"
echo "Остановка:                docker-compose down"
echo "Перезапуск сервиса:       docker-compose restart [service]"
echo "Обновить DAGs в Airflow:  docker-compose restart airflow-webserver airflow-scheduler"
echo ""
echo "✅ Инфраструктура запущена! Начинайте работу."