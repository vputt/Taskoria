package service

import (
	"strings"
	"time"

	"taskoria-go/internal/domain"
)

func validateCreateTaskInput(userID int64, input CreateTaskInput, now time.Time) error {
	if userID <= 0 {
		return ErrInvalidUserID
	}

	if strings.TrimSpace(input.Title) == "" {
		return ErrInvalidTitle
	}

	if !isValidTaskCategory(input.Category) {
		return ErrInvalidCategory
	}

	if !isValidTaskPriority(input.Priority) {
		return ErrInvalidPriority
	}

	if !isValidTaskDifficulty(input.Difficulty) {
		return ErrInvalidDifficulty
	}

	if input.Deadline != nil && !input.Deadline.After(now) {
		return ErrInvalidDeadline
	}

	return nil
}

func validateUpdateTaskInput(input UpdateTaskInput, now time.Time) error {
	if input.Title != nil && strings.TrimSpace(*input.Title) == "" {
		return ErrInvalidTitle
	}

	if input.Category != nil && !isValidTaskCategory(*input.Category) {
		return ErrInvalidCategory
	}

	if input.Priority != nil && !isValidTaskPriority(*input.Priority) {
		return ErrInvalidPriority
	}

	if input.Difficulty != nil && !isValidTaskDifficulty(*input.Difficulty) {
		return ErrInvalidDifficulty
	}

	if input.ClearDeadline && input.Deadline != nil {
		return ErrDeadlineConflict
	}

	if input.Deadline != nil && !input.Deadline.After(now) {
		return ErrInvalidDeadline
	}

	return nil
}

func isValidTaskCategory(category domain.TaskCategory) bool {
	switch category {
	case domain.TaskCategoryStudy,
		domain.TaskCategoryWork,
		domain.TaskCategoryHealth,
		domain.TaskCategoryPersonal:
		return true
	default:
		return false
	}
}

func isValidTaskPriority(priority domain.TaskPriority) bool {
	switch priority {
	case domain.TaskPriorityLow,
		domain.TaskPriorityMedium,
		domain.TaskPriorityHigh:
		return true
	default:
		return false
	}
}

func isValidTaskDifficulty(difficulty domain.TaskDifficulty) bool {
	switch difficulty {
	case domain.TaskDifficultyEasy,
		domain.TaskDifficultyMedium,
		domain.TaskDifficultyHard:
		return true
	default:
		return false
	}
}
