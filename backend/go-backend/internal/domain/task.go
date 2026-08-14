package domain

import "time"

type TaskCategory string

const (
	TaskCategoryStudy    TaskCategory = "study"
	TaskCategoryWork     TaskCategory = "work"
	TaskCategoryHealth   TaskCategory = "health"
	TaskCategoryPersonal TaskCategory = "personal"
)

type TaskPriority string

const (
	TaskPriorityLow    TaskPriority = "low"
	TaskPriorityMedium TaskPriority = "medium"
	TaskPriorityHigh   TaskPriority = "high"
)

type TaskStatus string

const (
	TaskStatusActive     TaskStatus = "active"
	TaskStatusInProgress TaskStatus = "in_progress"
	TaskStatusCompleted  TaskStatus = "completed"
	TaskStatusCancelled  TaskStatus = "cancelled"
)

type TaskDifficulty string

const (
	TaskDifficultyEasy   TaskDifficulty = "easy"
	TaskDifficultyMedium TaskDifficulty = "medium"
	TaskDifficultyHard   TaskDifficulty = "hard"
)

type Task struct {
	ID          int64
	UserID      int64
	Title       string
	Description string

	Category   TaskCategory
	Priority   TaskPriority
	Difficulty TaskDifficulty
	Status     TaskStatus

	XPReward    int
	CoinsReward int

	CreatedAt   time.Time
	UpdatedAt   time.Time
	Deadline    *time.Time
	CompletedAt *time.Time
}

func (t *Task) touch() {
	t.UpdatedAt = time.Now()
}

func (t *Task) Start() {
	if t.Status == TaskStatusActive {
		t.Status = TaskStatusInProgress
		t.touch()
	}
}

func (t *Task) Complete() {
	now := time.Now()
	t.Status = TaskStatusCompleted
	t.CompletedAt = &now
	t.UpdatedAt = now
}

func (t *Task) Cancel() {
	t.Status = TaskStatusCancelled
	t.touch()
}
