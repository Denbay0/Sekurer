from urllib.parse import quote_plus

from pydantic import AliasChoices, EmailStr, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "AI Call Assistant API"
    api_v1_prefix: str = "/api/v1"
    app_env: str = "development"
    secret_key: str = Field(default="change-me", validation_alias="SECRET_KEY")
    access_token_expire_minutes: int = 60 * 24
    algorithm: str = "HS256"

    database_url_env: str | None = Field(default=None, validation_alias="DATABASE_URL")
    db_host: str = Field(default="postgres-1", validation_alias="DB_HOST")
    db_port: int = Field(default=5432, validation_alias="DB_PORT")
    db_user: str = Field(default="sekurer", validation_alias="DB_USER")
    db_password: str = Field(default="sekurer_password", validation_alias="DB_PASSWORD")
    db_name: str = Field(default="sekurer", validation_alias="DB_NAME")

    redis_url_env: str | None = Field(default=None, validation_alias="REDIS_URL")
    redis_host: str = Field(default="redis-1", validation_alias="REDIS_HOST")
    redis_port: int = Field(default=6379, validation_alias="REDIS_PORT")
    redis_db: int = Field(default=0, validation_alias="REDIS_DB")

    s3_endpoint_url_env: str | None = Field(default=None, validation_alias="S3_ENDPOINT_URL")
    minio_host: str = Field(default="minio-1:9000", validation_alias="MINIO_HOST")
    s3_access_key: str = Field(default="minio", validation_alias=AliasChoices("S3_ACCESS_KEY", "MINIO_ROOT_USER"))
    s3_secret_key: str = Field(default="minio123", validation_alias=AliasChoices("S3_SECRET_KEY", "MINIO_ROOT_PASSWORD"))
    s3_bucket: str = "call-audio"

    log_file: str = Field(default="logs/api.log", validation_alias="LOG_FILE")
    service_check_attempts: int = Field(default=5, validation_alias="SERVICE_CHECK_ATTEMPTS")
    service_check_delay_seconds: float = Field(default=2.0, validation_alias="SERVICE_CHECK_DELAY_SECONDS")

    openai_api_key: str = "replace-me"
    transcribe_model: str = "gpt-4o-mini-transcribe"
    analysis_model: str = "gpt-4.1-mini"

    smtp_host: str = "smtp.example.com"
    smtp_port: int = 587
    smtp_username: EmailStr = "user@example.com"
    smtp_password: str = "password"
    smtp_from: EmailStr = "user@example.com"

    @property
    def database_url(self) -> str:
        if self.database_url_env:
            return self.database_url_env

        user = quote_plus(self.db_user)
        password = quote_plus(self.db_password)
        name = quote_plus(self.db_name)
        return f"postgresql+psycopg://{user}:{password}@{self.db_host}:{self.db_port}/{name}"

    @property
    def redis_url(self) -> str:
        if self.redis_url_env:
            return self.redis_url_env
        return f"redis://{self.redis_host}:{self.redis_port}/{self.redis_db}"

    @property
    def s3_endpoint_url(self) -> str:
        if self.s3_endpoint_url_env:
            return self.s3_endpoint_url_env
        if self.minio_host.startswith(("http://", "https://")):
            return self.minio_host
        return f"http://{self.minio_host}"


settings = Settings()
