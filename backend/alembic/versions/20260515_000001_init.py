"""init

Revision ID: 20260515_000001
Revises:
Create Date: 2026-05-15
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "20260515_000001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("users", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("email", sa.String(255), nullable=False), sa.Column("password_hash", sa.String(255), nullable=False), sa.Column("name", sa.String(255), nullable=False), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False), sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False))
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table("calls", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("title", sa.String(255)), sa.Column("contact_name", sa.String(255)), sa.Column("phone_number", sa.String(64)), sa.Column("audio_file_url", sa.Text()), sa.Column("audio_original_filename", sa.String(255)), sa.Column("audio_content_type", sa.String(128)), sa.Column("audio_size_bytes", sa.Integer()), sa.Column("transcript", sa.Text()), sa.Column("summary", sa.Text()), sa.Column("status", sa.Enum("uploaded", "transcribing", "analyzing", "ready", "failed", name="callstatus"), nullable=False, server_default="uploaded"), sa.Column("error_message", sa.Text()), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False), sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False), sa.Column("processed_at", sa.DateTime(timezone=True)))
    op.create_index("ix_calls_user_id", "calls", ["user_id"], unique=False)

    op.create_table("agreements", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("call_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("calls.id", ondelete="CASCADE"), nullable=False), sa.Column("text", sa.Text(), nullable=False), sa.Column("owner", sa.Enum("me", "other", "unknown", name="agreementowner"), nullable=False, server_default="unknown"), sa.Column("deadline", sa.Date()), sa.Column("confidence", sa.Float()), sa.Column("source_quote", sa.Text()), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False))
    op.create_index("ix_agreements_call_id", "agreements", ["call_id"], unique=False)

    op.create_table("tasks", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("call_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("calls.id", ondelete="CASCADE"), nullable=False), sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("title", sa.String(255), nullable=False), sa.Column("description", sa.Text()), sa.Column("due_date", sa.Date()), sa.Column("priority", sa.Enum("low", "medium", "high", name="taskpriority"), nullable=False, server_default="medium"), sa.Column("status", sa.Enum("draft", "confirmed", "done", "cancelled", name="taskstatus"), nullable=False, server_default="draft"), sa.Column("source_quote", sa.Text()), sa.Column("requires_confirmation", sa.Boolean(), nullable=False, server_default=sa.true()), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False), sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False))
    op.create_index("ix_tasks_call_id", "tasks", ["call_id"], unique=False)
    op.create_index("ix_tasks_user_id", "tasks", ["user_id"], unique=False)

    op.create_table("calendar_items", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("call_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("calls.id", ondelete="CASCADE"), nullable=False), sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("title", sa.String(255), nullable=False), sa.Column("description", sa.Text()), sa.Column("start_time", sa.DateTime(timezone=True)), sa.Column("end_time", sa.DateTime(timezone=True)), sa.Column("status", sa.Enum("draft", "confirmed", "cancelled", name="calendaritemstatus"), nullable=False, server_default="draft"), sa.Column("requires_confirmation", sa.Boolean(), nullable=False, server_default=sa.true()), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False), sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False))
    op.create_index("ix_calendar_items_call_id", "calendar_items", ["call_id"], unique=False)
    op.create_index("ix_calendar_items_user_id", "calendar_items", ["user_id"], unique=False)

    op.create_table("unclear_points", sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True), sa.Column("call_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("calls.id", ondelete="CASCADE"), nullable=False), sa.Column("text", sa.Text(), nullable=False), sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False))
    op.create_index("ix_unclear_points_call_id", "unclear_points", ["call_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_unclear_points_call_id", table_name="unclear_points")
    op.drop_table("unclear_points")
    op.drop_index("ix_calendar_items_user_id", table_name="calendar_items")
    op.drop_index("ix_calendar_items_call_id", table_name="calendar_items")
    op.drop_table("calendar_items")
    op.drop_index("ix_tasks_user_id", table_name="tasks")
    op.drop_index("ix_tasks_call_id", table_name="tasks")
    op.drop_table("tasks")
    op.drop_index("ix_agreements_call_id", table_name="agreements")
    op.drop_table("agreements")
    op.drop_index("ix_calls_user_id", table_name="calls")
    op.drop_table("calls")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
