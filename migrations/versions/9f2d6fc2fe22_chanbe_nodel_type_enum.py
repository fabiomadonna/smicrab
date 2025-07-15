"""chanbe_nodel_type_enum


Revision ID: 9f2d6fc2fe22
Revises: d4c65344d1a4
Create Date: 2025-07-14 16:56:56.569840

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9f2d6fc2fe22'
down_revision: Union[str, None] = 'd4c65344d1a4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Rename the existing enum type
    op.execute('ALTER TYPE modeltype RENAME TO modeltype_old')

    # Create a new enum type with the additional model_type
    op.execute("""
        CREATE TYPE modeltype AS ENUM (
            'Model1_Simple',
            'Model2_Autoregressive',
            'Model3_MB_User',
            'Model4_UHI',
            'Model5_RAB',
            'Model6_HSDPD_user'
        )
    """)

    # Alter the column to use the new enum type
    op.execute("""
        ALTER TABLE analysis 
        ALTER COLUMN model_type TYPE modeltype 
        USING model_type::text::modeltype
    """)

    # Drop the old enum type
    op.execute('DROP TYPE modeltype_old')


def downgrade() -> None:
    # Rename the existing enum type
    op.execute('ALTER TYPE modeltype RENAME TO modeltype_new')

    # Create the old enum type
    op.execute("""
        CREATE TYPE modeltype AS ENUM (
            'Model1_Simple',
            'Model2_Autoregressive',
            'Model3_MB_User',
            'Model4_UHU',
            'Model5_RAB',
            'Model6_HSDPD_user'
        )
    """)

    # Alter the column to use the old enum type
    op.execute("""
        ALTER TABLE analysis 
        ALTER COLUMN model_type TYPE modeltype 
        USING (
            CASE 
                WHEN model_type::text = 'Model4_UHI' THEN 'Model4_UHU'::modeltype 
                ELSE model_type::text::modeltype 
            END
        )
    """)

    # Drop the new enum type
    op.execute('DROP TYPE modeltype_new') 