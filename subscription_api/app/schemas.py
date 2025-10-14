from typing import Optional
from pydantic import BaseModel, Field, EmailStr


class SubscriptionCreate(BaseModel):
    email: EmailStr = Field(..., description="Подписчик")
    event_type: str = Field(..., min_length=1, max_length=100, description="Тип события")


class SubscriptionOut(BaseModel):
    id: int
    email: EmailStr
    event_type: str

    class Config:
        from_attributes = True

