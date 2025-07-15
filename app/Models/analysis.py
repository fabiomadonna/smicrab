from sqlalchemy import Column, Text, TIMESTAMP, Enum, ForeignKey, Index, Boolean
from sqlalchemy.sql.functions import func
from sqlalchemy.dialects.postgresql import UUID as PG_UUID, JSONB
import enum
import uuid
from app.Models.base_model import Base
from app.utils.enums import ModuleName, ModelType, AnalyzeStatus


class Analysis(Base):
    __tablename__ = "analysis"
    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        PG_UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="CASCADE"),
        nullable=False,
    )

    status = Column(Enum(AnalyzeStatus), nullable=False, default=AnalyzeStatus.pending)

    # Keep current_module for backward compatibility, but it will be deprecated
    current_module = Column(
        Enum(ModuleName), nullable=False, default=ModuleName.load_module
    )

    # New columns for refactored structure
    model_config = Column(JSONB, nullable=True)
    model_type = Column(Enum(ModelType), nullable=True)
    coordinates = Column(JSONB, nullable=True)
    is_dynamic_output = Column(Boolean, nullable=True, default=False)
    analysis_date = Column(TIMESTAMP, nullable=True)

    error_message = Column(Text)
    expires_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        Index("idx_analysis_user_id", "user_id"),
        Index("idx_analysis_id", "id"),
    )
