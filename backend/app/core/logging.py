import logging
import re
from logging.handlers import RotatingFileHandler
from pathlib import Path

from app.core.config import settings

SECRET_PATTERN = re.compile(
    r"(?i)(password|passwd|secret|token|access_key|secret_key|authorization)(['\"]?\s*[:=]\s*['\"]?)([^'\"\s,}]+)"
)


def redact_secrets(value: object) -> str:
    text = str(value)
    return SECRET_PATTERN.sub(r"\1\2***", text)


class RedactingFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return redact_secrets(super().format(record))


def configure_logging() -> None:
    log_path = Path(settings.log_file)
    if not log_path.is_absolute():
        log_path = Path.cwd() / log_path
    log_path.parent.mkdir(parents=True, exist_ok=True)

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)

    resolved_log_path = str(log_path.resolve())
    for handler in root_logger.handlers:
        if isinstance(handler, RotatingFileHandler) and handler.baseFilename == resolved_log_path:
            handler.filters.clear()
            handler.setFormatter(RedactingFormatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
            return

    file_handler = RotatingFileHandler(resolved_log_path, maxBytes=2_000_000, backupCount=5, encoding="utf-8")
    file_handler.setFormatter(RedactingFormatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
    root_logger.addHandler(file_handler)
