package httpapi

import (
	"time"

	"taskoria-go/internal/domain"
	"taskoria-go/internal/service"
)

type createTaskRequest struct {
	Title       string                `json:"title"`
	Description string                `json:"description"`
	Category    domain.TaskCategory   `json:"category"`
	Priority    domain.TaskPriority   `json:"priority"`
	Difficulty  domain.TaskDifficulty `json:"difficulty"`
	Deadline    *time.Time            `json:"deadline"`
}

type updateTaskRequest struct {
	Title         *string                `json:"title"`
	Description   *string                `json:"description"`
	Category      *domain.TaskCategory   `json:"category"`
	Priority      *domain.TaskPriority   `json:"priority"`
	Difficulty    *domain.TaskDifficulty `json:"difficulty"`
	Deadline      *time.Time             `json:"deadline"`
	ClearDeadline bool                   `json:"clear_deadline"`
}

type taskResponse struct {
	ID          int64  `json:"id"`
	UserID      int64  `json:"user_id"`
	Title       string `json:"title"`
	Description string `json:"description"`

	Category   domain.TaskCategory   `json:"category"`
	Priority   domain.TaskPriority   `json:"priority"`
	Difficulty domain.TaskDifficulty `json:"difficulty"`
	Status     domain.TaskStatus     `json:"status"`

	XPReward    int `json:"xp_reward"`
	CoinsReward int `json:"coins_reward"`

	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
	Deadline    *time.Time `json:"deadline"`
	CompletedAt *time.Time `json:"completed_at"`
}

func (r createTaskRequest) toServiceInput() service.CreateTaskInput {
	return service.CreateTaskInput{
		Title:       r.Title,
		Description: r.Description,
		Category:    r.Category,
		Priority:    r.Priority,
		Difficulty:  r.Difficulty,
		Deadline:    r.Deadline,
	}
}

func (r updateTaskRequest) toServiceInput() service.UpdateTaskInput {
	return service.UpdateTaskInput{
		Title:         r.Title,
		Description:   r.Description,
		Category:      r.Category,
		Priority:      r.Priority,
		Difficulty:    r.Difficulty,
		Deadline:      r.Deadline,
		ClearDeadline: r.ClearDeadline,
	}
}

func newTaskResponse(task *domain.Task) taskResponse {
	return taskResponse{
		ID:          task.ID,
		UserID:      task.UserID,
		Title:       task.Title,
		Description: task.Description,
		Category:    task.Category,
		Priority:    task.Priority,
		Difficulty:  task.Difficulty,
		Status:      task.Status,
		XPReward:    task.XPReward,
		CoinsReward: task.CoinsReward,
		CreatedAt:   task.CreatedAt,
		UpdatedAt:   task.UpdatedAt,
		Deadline:    task.Deadline,
		CompletedAt: task.CompletedAt,
	}
}
