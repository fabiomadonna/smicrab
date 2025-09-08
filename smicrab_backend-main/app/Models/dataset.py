from sqlalchemy import Column, Integer, VARCHAR, Text, Numeric, TIMESTAMP, Index
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
import uuid
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import JSONB

from app.Models.base_model import Base


class Dataset(Base):
    __tablename__ = "datasets"
    id = Column(PG_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(VARCHAR(255), nullable=False)
    raster = Column(VARCHAR(255), nullable=False)
    variable_name = Column(VARCHAR(255), nullable=False)
    from_timestamp = Column(TIMESTAMP, nullable=False)
    to_timestamp = Column(TIMESTAMP, nullable=False)
    longitude_from = Column(Numeric(10, 6))
    longitude_to = Column(Numeric(10, 6))
    latitude_from = Column(Numeric(10, 6))
    latitude_to = Column(Numeric(10, 6))
    frequency = Column(VARCHAR(50), nullable=False)
    grid_resolution = Column(VARCHAR(50))
    file_path = Column(Text)
    file_size_mb = Column(Numeric(10, 2))
    dimensions = Column(JSONB)
    data_vars = Column(JSONB)
    time_coords = Column(JSONB)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(
        TIMESTAMP(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    __table_args__ = (
        Index("idx_datasets_variable_name", "variable_name"),
        Index("idx_datasets_frequency", "frequency"),
        Index("idx_datasets_from_timestamp", "from_timestamp"),
        Index("idx_datasets_to_timestamp", "to_timestamp"),
    )
