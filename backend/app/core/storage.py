from dataclasses import dataclass

from app.core.config import settings


@dataclass(slots=True)
class StorageConfig:
    endpoint_url: str
    access_key: str
    secret_key: str
    bucket: str


storage_config = StorageConfig(
    endpoint_url=settings.s3_endpoint_url,
    access_key=settings.s3_access_key,
    secret_key=settings.s3_secret_key,
    bucket=settings.s3_bucket,
)
