from fastapi import FastAPI, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from .db import Base, engine, get_db
from .models import Subscription
from .schemas import SubscriptionCreate, SubscriptionOut


app = FastAPI(title="Subscription API", version="1.0.0")


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/subscriptions", response_model=SubscriptionOut, status_code=status.HTTP_201_CREATED)
def create_subscription(payload: SubscriptionCreate, response: Response, db: Session = Depends(get_db)):
    sub = Subscription(email=str(payload.email), event_type=payload.event_type)
    db.add(sub)
    try:
        db.commit()
        db.refresh(sub)
        return sub
    except IntegrityError:
        db.rollback()
        # Already exists: return existing entry with 200 OK to make it idempotent
        existing = db.execute(
            select(Subscription).where(
                Subscription.email == str(payload.email),
                Subscription.event_type == payload.event_type,
            )
        ).scalar_one()
        response.status_code = status.HTTP_200_OK
        return existing


@app.get("/subscriptions", response_model=list[SubscriptionOut])
def list_subscriptions(event_type: str | None = None, email: str | None = None, db: Session = Depends(get_db)):
    stmt = select(Subscription)
    if event_type:
        stmt = stmt.where(Subscription.event_type == event_type)
    if email:
        stmt = stmt.where(Subscription.email == email)
    rows = db.execute(stmt.order_by(Subscription.id.desc())).scalars().all()
    return rows


@app.get("/subscriptions/{sub_id}", response_model=SubscriptionOut)
def get_subscription(sub_id: int, db: Session = Depends(get_db)):
    obj = db.get(Subscription, sub_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return obj

