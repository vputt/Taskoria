"""
Policies for city progression derived from completed tasks.
"""
from dataclasses import dataclass

from app.models.task import TaskCategory


@dataclass(frozen=True)
class CityProgressionPolicy:
    """Encapsulates city progression rules."""

    layout_order: tuple[TaskCategory, ...] = (
        TaskCategory.STUDY,
        TaskCategory.WORK,
        TaskCategory.HEALTH,
        TaskCategory.PERSONAL,
    )
    level_thresholds: tuple[tuple[int, int], ...] = (
        (3, 3),
        (2, 2),
        (1, 1),
    )
    anchor_spacing: int = 2

    def get_target_level(self, completed_tasks: int) -> int:
        """Maps completed task count to the target building level."""
        for threshold, level in self.level_thresholds:
            if completed_tasks >= threshold:
                return level
        return 0

    def get_anchor_position(self, category: TaskCategory) -> tuple[int, int]:
        """Returns the preferred anchor cell for the category building."""
        index = self.layout_order.index(category)
        return (
            (index % 2) * self.anchor_spacing,
            (index // 2) * self.anchor_spacing,
        )
