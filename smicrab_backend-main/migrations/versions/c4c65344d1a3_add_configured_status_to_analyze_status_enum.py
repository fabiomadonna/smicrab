"""add configured status to AnalyzeStatus enum

Revision ID: c4c65344d1a3
Revises: b4c65344d1a2
Create Date: 2025-07-10 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'c4c65344d1a3'
down_revision: Union[str, None] = 'b4c65344d1a2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Rename the existing enum type
    op.execute('ALTER TYPE analyzestatus RENAME TO analyzestatus_old')

    # Create a new enum type with the additional status
    op.execute("""
        CREATE TYPE analyzestatus AS ENUM (
            'pending', 
            'configured', 
            'in_progress', 
            'completed', 
            'error'
        )
    """)

    # Alter the column to use the new enum type
    op.execute("""
        ALTER TABLE analysis 
        ALTER COLUMN status TYPE analyzestatus 
        USING status::text::analyzestatus
    """)

    # Drop the old enum type
    op.execute('DROP TYPE analyzestatus_old')


def downgrade() -> None:
    # Rename the existing enum type
    op.execute('ALTER TYPE analyzestatus RENAME TO analyzestatus_new')

    # Create the old enum type
    op.execute("""
        CREATE TYPE analyzestatus AS ENUM (
            'pending', 
            'ready_to_run', 
            'in_progress', 
            'completed', 
            'error'
        )
    """)

    # Alter the column to use the old enum type
    op.execute("""
        ALTER TABLE analysis 
        ALTER COLUMN status TYPE analyzestatus 
        USING (
            CASE 
                WHEN status::text = 'configured' THEN 'ready_to_run'::analyzestatus 
                ELSE status::text::analyzestatus 
            END
        )
    """)

    # Drop the new enum type
    op.execute('DROP TYPE analyzestatus_new') 