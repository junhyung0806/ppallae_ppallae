from datetime import datetime
from uuid import uuid4

from geoalchemy2 import Geography
from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def _uuid():
    return uuid4()


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=_uuid)
    nickname: Mapped[str] = mapped_column(String(80), nullable=False)
    home_region_label: Mapped[str | None] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    saved_locations: Mapped[list["SavedLocation"]] = relationship(back_populates="user")
    laundry_runs: Mapped[list["LaundryRun"]] = relationship(back_populates="user")


class SavedLocation(Base):
    __tablename__ = "saved_locations"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=_uuid)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    label: Mapped[str] = mapped_column(String(120), nullable=False)
    address: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    point = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="saved_locations")


class Laundromat(Base):
    __tablename__ = "laundromats"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String(140), nullable=False)
    address: Mapped[str] = mapped_column(String(255), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    point = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=False)
    machine_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    dryer_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    open_24_hours: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    recommendation_boost: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    tags: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class LaundryRun(Base):
    __tablename__ = "laundry_runs"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=_uuid)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False)
    location_label: Mapped[str | None] = mapped_column(String(120))
    start_hour: Mapped[int] = mapped_column(Integer, nullable=False)
    dry_minutes: Mapped[int | None] = mapped_column(Integer)
    recommended: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="laundry_runs")


class WeatherCacheEntry(Base):
    __tablename__ = "weather_cache_entries"

    id: Mapped[UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=_uuid)
    cache_key: Mapped[str] = mapped_column(String(120), unique=True, index=True, nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

