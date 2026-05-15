from app.workers.celery_app import celery_app


@celery_app.task(name="process_call")
def process_call(call_id: str) -> None:
    _ = call_id
