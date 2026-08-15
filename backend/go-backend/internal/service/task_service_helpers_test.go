package service

import (
	"errors"
	"testing"
	"time"

	"taskoria-go/internal/domain"
)

func validCreateTaskInput() CreateTaskInput {
	return CreateTaskInput{
		Title:      "Task",
		Category:   domain.TaskCategoryStudy,
		Priority:   domain.TaskPriorityHigh,
		Difficulty: domain.TaskDifficultyMedium,
	}
}

func testTask(id int64, userID int64, status domain.TaskStatus) *domain.Task {
	now := time.Now().Add(-2 * time.Hour)

	return &domain.Task{
		ID:          id,
		UserID:      userID,
		Title:       "Task",
		Description: "Task description",
		Category:    domain.TaskCategoryStudy,
		Priority:    domain.TaskPriorityMedium,
		Difficulty:  domain.TaskDifficultyMedium,
		Status:      status,
		XPReward:    10,
		CoinsReward: 100,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

func strPtr(value string) *string {
	return &value
}

func requireErrorIs(t *testing.T, got error, want error) {
	t.Helper()

	if !errors.Is(got, want) {
		t.Fatalf("expected error %v, got %v", want, got)
	}
}
