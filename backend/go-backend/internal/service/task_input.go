package service

import (
	"time"

	"taskoria-go/internal/domain"
)

type CreateTaskInput struct {
	Title       string
	Description string

	Category   domain.TaskCategory
	Priority   domain.TaskPriority
	Difficulty domain.TaskDifficulty

	Deadline *time.Time
}

type UpdateTaskInput struct {
	Title       *string
	Description *string
	Category    *domain.TaskCategory
	Priority    *domain.TaskPriority
	Difficulty  *domain.TaskDifficulty
	Deadline    *time.Time

	ClearDeadline bool
}
