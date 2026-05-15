from pydantic import EmailStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "AI Call Assistant API"
    api_v1_prefix: str = "/api/v1"
    app_env: str = "development"
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 60 * 24
    algorithm: str = "HS256"

    database_url: str = "postgresql+psycopg://postgres:postgres@postgres:5432/call_assistant"
    redis_url: str = "redis://redis:6379/0"

    s3_endpoint_url: str = "http://minio:9000"
    s3_access_key: str = "minio"
    s3_secret_key: str = "minio123"
    s3_bucket: str = "call-audio"

    openai_api_key: str = "replace-me"
    transcribe_model: str = "replace-me"
    analysis_model: str = "replace-me"

    smtp_host: str = "smtp.example.com"
    smtp_port: int = 587
    smtp_username: EmailStr = "user@example.com"
    smtp_password: str = "password"
    smtp_from: EmailStr = "user@example.com"


settings = Settings()
