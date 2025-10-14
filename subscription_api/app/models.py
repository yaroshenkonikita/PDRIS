from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, UniqueConstraint, Index
from .db import Base


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(320), nullable=False)
    event_type = Column(String(100), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("email", "event_type", name="uq_email_event"),
        Index("ix_email", "email"),
        Index("ix_event_type", "event_type"),
    )

