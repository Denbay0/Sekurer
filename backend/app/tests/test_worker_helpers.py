from datetime import date, datetime

from app.db.models import AgreementOwner, TaskPriority
from app.workers.tasks import parse_date_or_none, parse_datetime_or_none, safe_agreement_owner, safe_task_priority


def test_parse_date_or_none():
    assert parse_date_or_none(None) is None
    assert parse_date_or_none("") is None
    assert parse_date_or_none("2026-05-15") == date(2026, 5, 15)
    assert parse_date_or_none("invalid") is None


def test_parse_datetime_or_none():
    assert parse_datetime_or_none(None) is None
    assert parse_datetime_or_none("") is None
    assert parse_datetime_or_none("2026-05-15T12:30:00+00:00") == datetime.fromisoformat("2026-05-15T12:30:00+00:00")
    assert parse_datetime_or_none("2026-05-15T12:30:00Z") == datetime.fromisoformat("2026-05-15T12:30:00+00:00")
    assert parse_datetime_or_none("bad") is None


def test_safe_agreement_owner():
    assert safe_agreement_owner("me") == AgreementOwner.me
    assert safe_agreement_owner("other") == AgreementOwner.other
    assert safe_agreement_owner("unknown") == AgreementOwner.unknown
    assert safe_agreement_owner("weird") == AgreementOwner.unknown


def test_safe_task_priority():
    assert safe_task_priority("low") == TaskPriority.low
    assert safe_task_priority("medium") == TaskPriority.medium
    assert safe_task_priority("high") == TaskPriority.high
    assert safe_task_priority("critical") == TaskPriority.medium
