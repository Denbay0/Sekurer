import io
import re
import uuid
from pathlib import Path

import boto3
from botocore.client import BaseClient
from botocore.exceptions import ClientError

from app.core.config import settings


class StorageService:
    def __init__(self) -> None:
        self.bucket = settings.s3_bucket
        self.client: BaseClient = boto3.client(
            "s3",
            endpoint_url=settings.s3_endpoint_url,
            aws_access_key_id=settings.s3_access_key,
            aws_secret_access_key=settings.s3_secret_key,
        )

    @staticmethod
    def _safe_filename(filename: str) -> str:
        name = Path(filename).name
        return re.sub(r"[^a-zA-Z0-9_.-]", "_", name)

    def generate_object_key(self, user_id: str, call_id: str, filename: str) -> str:
        safe_filename = self._safe_filename(filename)
        return f"users/{user_id}/calls/{call_id}/{uuid.uuid4()}_{safe_filename}"

    def ensure_bucket_exists(self) -> None:
        try:
            self.client.head_bucket(Bucket=self.bucket)
        except ClientError as exc:
            error_code = str(exc.response.get("Error", {}).get("Code", ""))
            if error_code not in {"404", "NoSuchBucket", "NotFound"}:
                raise
            self.client.create_bucket(Bucket=self.bucket)

    def upload_fileobj(self, file_obj: io.BytesIO, object_key: str, content_type: str | None = None) -> str:
        extra_args = {"ContentType": content_type} if content_type else None
        self.client.upload_fileobj(file_obj, self.bucket, object_key, ExtraArgs=extra_args or {})
        return object_key

    def delete_object(self, object_key: str) -> None:
        self.client.delete_object(Bucket=self.bucket, Key=object_key)

    def get_object_bytes(self, object_key: str) -> bytes:
        obj = self.client.get_object(Bucket=self.bucket, Key=object_key)
        return obj["Body"].read()
