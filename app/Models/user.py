from typing import Optional

from typing_extensions import Annotated

from sqlalchemy import Column, String, TIMESTAMP
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import mapped_column, Mapped
import uuid
from app.Models.base_model import Base
from sqlalchemy import ForeignKey, BIGINT


class User(Base):
    __tablename__ = "users"
    user_id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())


# str_255 = Annotated[str, mapped_column(String(255))]
#
# # Users ForeignKey
# user_fk = Annotated[
#     int, mapped_column(BIGINT, ForeignKey("users.telegram_id", ondelete="CASCADE"))
# ]
#
#
# class Users(Base):
#
#     user_id: Mapped[int] = mapped_column(BIGINT, primary_key=True, autoincrement=False)
#     email: Mapped[str_255]
#     username: Mapped[Optional[str_255]]
#     language_code: Mapped[str_255]
#     referrer_id: Mapped[Optional[user_fk]]
