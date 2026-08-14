package domain

import (
	"testing"
	"time"
)

var oldUpdatedAt time.Time = time.Date(2026, 8, 14, 10, 0, 0, 0, time.UTC)

func TestTaskStart_ActiveTask(t *testing.T) {
	task := Task{
		Status:    TaskStatusActive,
		UpdatedAt: oldUpdatedAt,
	}

	task.Start()

	if task.Status != TaskStatusInProgress {
		t.Fatalf("expected status %q, got %q", TaskStatusInProgress, task.Status)
	}
	if task.UpdatedAt.Equal(oldUpdatedAt) {
		t.Fatal("expected updated at to change")
	}
}

func TestTaskStart_NonActiveTask(t *testing.T) {
	tests := []struct {
		name   string
		status TaskStatus
	}{
		{
			name:   "in progress task stays in progress",
			status: TaskStatusInProgress,
		},
		{
			name:   "completed task stays completed",
			status: TaskStatusCompleted,
		},
		{
			name:   "cancelled task stays cancelled",
			status: TaskStatusCancelled,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			task := Task{
				Status:    tt.status,
				UpdatedAt: oldUpdatedAt,
			}

			task.Start()

			if task.Status != tt.status {
				t.Fatalf("expected status %q, got %q", tt.status, task.Status)
			}
			if !task.UpdatedAt.Equal(oldUpdatedAt) {
				t.Fatal("expected updated at not to change")
			}
		})
	}
}

func TestTaskCancel(t *testing.T) {
	tests := []struct {
		name   string
		status TaskStatus
	}{
		{
			name:   "active -> cancelled",
			status: TaskStatusActive,
		},
		{
			name:   "in progress -> cancelled",
			status: TaskStatusInProgress,
		},
		{
			name:   "completed -> cancelled",
			status: TaskStatusCompleted,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			task := Task{
				Status:    tt.status,
				UpdatedAt: oldUpdatedAt,
			}

			task.Cancel()

			if task.Status != TaskStatusCancelled {
				t.Fatalf("expected status %q, got %q", TaskStatusCancelled, task.Status)
			}
			if task.UpdatedAt.Equal(oldUpdatedAt) {
				t.Fatalf("expected updated at to change")
			}
		})
	}
}

func TestTaskComplete(t *testing.T) {
	tests := []struct {
		name   string
		status TaskStatus
	}{
		{
			name:   "active -> completed",
			status: TaskStatusActive,
		},
		{
			name:   "in progress -> completed",
			status: TaskStatusInProgress,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			task := Task{
				Status:    tt.status,
				UpdatedAt: oldUpdatedAt,
			}

			task.Complete()

			if task.Status != TaskStatusCompleted {
				t.Fatalf("expected status %q, got %q", TaskStatusCompleted, task.Status)
			}
			if task.UpdatedAt.Equal(oldUpdatedAt) {
				t.Fatalf("expected updated at to change")
			}
			if task.CompletedAt == nil {
				t.Fatal("expected completed at to be set")
			}
		})
	}
}
