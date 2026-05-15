from datetime import UTC, datetime, timedelta
from typing import Any

from openai import OpenAI
from pydantic import BaseModel, Field, ValidationError

from app.core.config import settings


class AgreementOut(BaseModel):
    text: str
    owner: str = Field(default="unknown")
    deadline: str | None = None
    confidence: float = Field(default=0.7, ge=0.0, le=1.0)
    source_quote: str | None = None


class TaskOut(BaseModel):
    title: str
    description: str | None = None
    due_date: str | None = None
    priority: str = Field(default="medium")
    requires_confirmation: bool = True
    source_quote: str | None = None


class CalendarEventOut(BaseModel):
    title: str
    description: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    requires_confirmation: bool = True


class AnalysisOut(BaseModel):
    call_title: str
    summary: str
    agreements: list[AgreementOut]
    tasks: list[TaskOut]
    calendar_events: list[CalendarEventOut]
    unclear_points: list[str]


class AIService:
    def __init__(self) -> None:
        self.use_mock = not settings.openai_api_key or settings.openai_api_key == "replace-me"
        self.client = None if self.use_mock else OpenAI(api_key=settings.openai_api_key)

    def transcribe_audio(self, file_bytes: bytes, filename: str, content_type: str | None) -> str:
        if self.use_mock:
            return "Тестовая транскрипция: обсудили отправку КП, подготовку договора и звонок во вторник."
        transcript = self.client.audio.transcriptions.create(
            model=settings.transcribe_model,
            file=(filename, file_bytes, content_type or "application/octet-stream"),
        )
        return transcript.text

    def analyze_transcript(self, transcript: str, call_created_at: datetime | None = None) -> dict[str, Any]:
        if self.use_mock:
            base_date = (call_created_at or datetime.now(UTC)).date()
            due = (base_date + timedelta(days=2)).isoformat()
            return AnalysisOut(
                call_title="Звонок по коммерческому предложению",
                summary="Обсудили следующие шаги по КП и договору.",
                agreements=[AgreementOut(text="Отправить КП до конца дня", owner="me", deadline=due, confidence=0.86, source_quote="Отправлю КП сегодня")],
                tasks=[TaskOut(title="Подготовить и отправить КП", description="Добавить финальную цену и сроки", due_date=due, priority="high", requires_confirmation=True, source_quote="Я отправлю КП сегодня")],
                calendar_events=[],
                unclear_points=["Не уточнили итоговый бюджет проекта"],
            ).model_dump()

        prompt = (
            "Верни строго JSON с полями: call_title, summary, agreements, tasks, calendar_events, unclear_points. "
            "Не выдумывай задачи. Для каждой задачи укажи source_quote и requires_confirmation=true, если есть сомнения."
        )
        response = self.client.chat.completions.create(
            model=settings.analysis_model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": transcript},
            ],
        )
        content = response.choices[0].message.content or "{}"
        try:
            validated = AnalysisOut.model_validate_json(content)
        except ValidationError:
            validated = AnalysisOut(
                call_title="Разбор звонка",
                summary="Не удалось надёжно разобрать ответ модели.",
                agreements=[],
                tasks=[],
                calendar_events=[],
                unclear_points=["Требуется ручная проверка результата AI"],
            )
        return validated.model_dump()
