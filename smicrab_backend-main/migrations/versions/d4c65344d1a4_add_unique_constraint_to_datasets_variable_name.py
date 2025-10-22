"""add unique constraint to datasets variable_name

Revision ID: d4c65344d1a4
Revises: c4c65344d1a3
Create Date: 2025-07-10 16:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4c65344d1a4'
down_revision: Union[str, None] = 'c4c65344d1a3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add unique constraint to variable_name column
    op.create_index('uq_datasets_variable_name', 'datasets', ['variable_name'], unique=True)


def downgrade() -> None:
    # Remove the unique constraint
    op.drop_index('uq_datasets_variable_name', table_name='datasets') 