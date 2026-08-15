package memory

import (
	"errors"
	"testing"
	"time"

	"taskoria-go/internal/domain"
)

func testTask(userID int64, title string) *domain.Task {
	now := time.Now()

	return &domain.Task{
		UserID:      userID,
		Title:       title,
		Description: "Task description",
		Category:    domain.TaskCategoryStudy,
		Priority:    domain.TaskPriorityMedium,
		Difficulty:  domain.TaskDifficultyMedium,
		Status:      domain.TaskStatusActive,
		XPReward:    10,
		CoinsReward: 100,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
}

func requireErrorIs(t *testing.T, got error, want error) {
	t.Helper()

	if !errors.Is(got, want) {
		t.Fatalf("expected error %v, got %v", want, got)
	}
}
