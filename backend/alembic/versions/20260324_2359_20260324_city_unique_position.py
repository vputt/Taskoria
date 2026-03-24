"""Add unique constraint for user building position

Revision ID: 20260324_city_unique_position
Revises: bb799a9b9ba1
Create Date: 2026-03-24 23:59:00

"""
from alembic import op


# revision identifiers, used by Alembic.
revision = "20260324_city_unique_position"
down_revision = "bb799a9b9ba1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_unique_constraint(
        "uq_buildings_user_position",
        "buildings",
        ["user_id", "position_x", "position_y"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_buildings_user_position", "buildings", type_="unique")
