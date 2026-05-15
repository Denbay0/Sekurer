from dataclasses import dataclass

from app.core.config import settings


@dataclass(slots=True)
class EmailConfig:
    host: str
    port: int
    username: str
    password: str
    sender: str


email_config = EmailConfig(
    host=settings.smtp_host,
    port=settings.smtp_port,
    username=str(settings.smtp_username),
    password=settings.smtp_password,
    sender=str(settings.smtp_from),
)
