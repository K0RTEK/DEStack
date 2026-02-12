CREATE DATABASE analytics_db;
CREATE DATABASE warehouse_db;
CREATE DATABASE test_db;

CREATE USER readonly WITH PASSWORD 'readonly_pass';
GRANT CONNECT ON DATABASE app_db TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

\c app_db;

CREATE SCHEMA IF NOT EXISTS app_schema;

CREATE TABLE IF NOT EXISTS app_schema.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_schema.sensor_data (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(100)
);

INSERT INTO app_schema.users (username, email)
VALUES
    ('test_user', 'test@example.com'),
    ('admin', 'admin@example.com')
ON CONFLICT (username) DO NOTHING;

CREATE OR REPLACE VIEW app_schema.user_summary AS
SELECT
    COUNT(*) as total_users,
    MIN(created_at) as first_user_date,
    MAX(created_at) as last_user_date
FROM app_schema.users;

CREATE OR REPLACE FUNCTION app_schema.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON app_schema.users
    FOR EACH ROW
    EXECUTE FUNCTION app_schema.update_updated_at_column();