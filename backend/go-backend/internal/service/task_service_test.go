package service

import (
	"errors"
	"testing"
	"time"

	"taskoria-go/internal/domain"
)

func TestTaskService_CreateTask(t *testing.T) {
	repo := newFakeTaskRepository()
	service := NewTaskService(repo)
	deadline := time.Now().Add(24 * time.Hour)
	before := time.Now()

	task, err := service.CreateTask(10, CreateTaskInput{
		Title:       "  Learn Go  ",
		Description: "Practice service tests",
		Category:    domain.TaskCategoryStudy,
		Priority:    domain.TaskPriorityHigh,
		Difficulty:  domain.TaskDifficultyMedium,
		Deadline:    &deadline,
	})
	after := time.Now()

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if task == nil {
		t.Fatal("expected task, got nil")
	}

	if repo.createCalls != 1 {
		t.Fatalf("expected Create to be called once, got %d", repo.createCalls)
	}

	if repo.createdTask != task {
		t.Fatal("expected repository to receive the returned task")
	}

	if task.UserID != 10 {
		t.Fatalf("expected user id 10, got %d", task.UserID)
	}

	if task.Title != "Learn Go" {
		t.Fatalf("expected trimmed title, got %q", task.Title)
	}

	if task.Status != domain.TaskStatusActive {
		t.Fatalf("expected status %q, got %q", domain.TaskStatusActive, task.Status)
	}

	if task.XPReward != 10 {
		t.Fatalf("expected xp reward 10, got %d", task.XPReward)
	}

	if task.CoinsReward != 100 {
		t.Fatalf("expected coins reward 100, got %d", task.CoinsReward)
	}

	if task.CreatedAt.IsZero() {
		t.Fatal("expected CreatedAt to be set")
	}

	if task.UpdatedAt.IsZero() {
		t.Fatal("expected UpdatedAt to be set")
	}

	if task.CreatedAt.Before(before) || task.CreatedAt.After(after) {
		t.Fatalf("expected CreatedAt to be between test timestamps, got %s", task.CreatedAt)
	}

	if !task.CreatedAt.Equal(task.UpdatedAt) {
		t.Fatalf("expected CreatedAt and UpdatedAt to be equal, got %s and %s", task.CreatedAt, task.UpdatedAt)
	}
}

func TestTaskService_CreateTaskValidation(t *testing.T) {
	pastDeadline := time.Now().Add(-time.Hour)

	tests := []struct {
		name    string
		userID  int64
		input   CreateTaskInput
		wantErr error
	}{
		{
			name:    "invalid user id",
			userID:  0,
			input:   validCreateTaskInput(),
			wantErr: ErrInvalidUserID,
		},
		{
			name:   "blank title",
			userID: 10,
			input: CreateTaskInput{
				Title:      "   ",
				Category:   domain.TaskCategoryStudy,
				Priority:   domain.TaskPriorityHigh,
				Difficulty: domain.TaskDifficultyMedium,
			},
			wantErr: ErrInvalidTitle,
		},
		{
			name:   "invalid category",
			userID: 10,
			input: CreateTaskInput{
				Title:      "Task",
				Category:   domain.TaskCategory("unknown"),
				Priority:   domain.TaskPriorityHigh,
				Difficulty: domain.TaskDifficultyMedium,
			},
			wantErr: ErrInvalidCategory,
		},
		{
			name:   "invalid priority",
			userID: 10,
			input: CreateTaskInput{
				Title:      "Task",
				Category:   domain.TaskCategoryStudy,
				Priority:   domain.TaskPriority("urgent"),
				Difficulty: domain.TaskDifficultyMedium,
			},
			wantErr: ErrInvalidPriority,
		},
		{
			name:   "invalid difficulty",
			userID: 10,
			input: CreateTaskInput{
				Title:      "Task",
				Category:   domain.TaskCategoryStudy,
				Priority:   domain.TaskPriorityHigh,
				Difficulty: domain.TaskDifficulty("impossible"),
			},
			wantErr: ErrInvalidDifficulty,
		},
		{
			name:   "past deadline",
			userID: 10,
			input: CreateTaskInput{
				Title:      "Task",
				Category:   domain.TaskCategoryStudy,
				Priority:   domain.TaskPriorityHigh,
				Difficulty: domain.TaskDifficultyMedium,
				Deadline:   &pastDeadline,
			},
			wantErr: ErrInvalidDeadline,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := newFakeTaskRepository()
			service := NewTaskService(repo)

			task, err := service.CreateTask(tt.userID, tt.input)

			requireErrorIs(t, err, tt.wantErr)

			if task != nil {
				t.Fatalf("expected nil task, got %#v", task)
			}

			if repo.createCalls != 0 {
				t.Fatalf("expected Create not to be called, got %d calls", repo.createCalls)
			}
		})
	}
}

func TestTaskService_GetTask(t *testing.T) {
	repoErr := errors.New("repository failed")

	tests := []struct {
		name    string
		repo    *fakeTaskRepository
		userID  int64
		taskID  int64
		wantErr error
	}{
		{
			name:   "returns own task",
			repo:   newFakeTaskRepository(testTask(1, 10, domain.TaskStatusActive)),
			userID: 10,
			taskID: 1,
		},
		{
			name:    "missing task",
			repo:    newFakeTaskRepository(),
			userID:  10,
			taskID:  1,
			wantErr: ErrTaskNotFound,
		},
		{
			name:    "task belongs to another user",
			repo:    newFakeTaskRepository(testTask(1, 20, domain.TaskStatusActive)),
			userID:  10,
			taskID:  1,
			wantErr: ErrTaskNotFound,
		},
		{
			name: "repository error",
			repo: &fakeTaskRepository{
				tasks:  make(map[int64]*domain.Task),
				getErr: repoErr,
			},
			userID:  10,
			taskID:  1,
			wantErr: repoErr,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewTaskService(tt.repo)

			task, err := service.GetTask(tt.userID, tt.taskID)

			if tt.wantErr != nil {
				requireErrorIs(t, err, tt.wantErr)
				if task != nil {
					t.Fatalf("expected nil task, got %#v", task)
				}
				return
			}

			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}

			if task == nil {
				t.Fatal("expected task, got nil")
			}

			if task.ID != tt.taskID {
				t.Fatalf("expected task id %d, got %d", tt.taskID, task.ID)
			}
		})
	}
}

func TestTaskService_ListTasks(t *testing.T) {
	repo := newFakeTaskRepository(
		testTask(1, 10, domain.TaskStatusActive),
		testTask(2, 10, domain.TaskStatusCompleted),
		testTask(3, 20, domain.TaskStatusActive),
	)
	service := NewTaskService(repo)

	tasks, err := service.ListTasks(10)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if repo.listCalls != 1 {
		t.Fatalf("expected ListByUser to be called once, got %d", repo.listCalls)
	}

	if len(tasks) != 2 {
		t.Fatalf("expected 2 tasks, got %d", len(tasks))
	}

	for _, task := range tasks {
		if task.UserID != 10 {
			t.Fatalf("expected only user 10 tasks, got user %d", task.UserID)
		}
	}
}

func TestTaskService_UpdateTask(t *testing.T) {
	oldUpdatedAt := time.Now().Add(-time.Hour)
	task := testTask(1, 10, domain.TaskStatusActive)
	task.UpdatedAt = oldUpdatedAt
	oldDeadline := time.Now().Add(24 * time.Hour)
	task.Deadline = &oldDeadline

	repo := newFakeTaskRepository(task)
	service := NewTaskService(repo)

	newTitle := "  Updated title  "
	newDescription := "Updated description"
	newCategory := domain.TaskCategoryWork
	newPriority := domain.TaskPriorityLow
	newDifficulty := domain.TaskDifficultyHard
	newDeadline := time.Now().Add(48 * time.Hour)

	updatedTask, err := service.UpdateTask(10, 1, UpdateTaskInput{
		Title:       &newTitle,
		Description: &newDescription,
		Category:    &newCategory,
		Priority:    &newPriority,
		Difficulty:  &newDifficulty,
		Deadline:    &newDeadline,
	})

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if repo.saveCalls != 1 {
		t.Fatalf("expected Save to be called once, got %d", repo.saveCalls)
	}

	if repo.savedTask != updatedTask {
		t.Fatal("expected repository to save the returned task")
	}

	if updatedTask.Title != "Updated title" {
		t.Fatalf("expected trimmed title, got %q", updatedTask.Title)
	}

	if updatedTask.Description != newDescription {
		t.Fatalf("expected description %q, got %q", newDescription, updatedTask.Description)
	}

	if updatedTask.Category != newCategory {
		t.Fatalf("expected category %q, got %q", newCategory, updatedTask.Category)
	}

	if updatedTask.Priority != newPriority {
		t.Fatalf("expected priority %q, got %q", newPriority, updatedTask.Priority)
	}

	if updatedTask.Difficulty != newDifficulty {
		t.Fatalf("expected difficulty %q, got %q", newDifficulty, updatedTask.Difficulty)
	}

	if updatedTask.Deadline == nil || !updatedTask.Deadline.Equal(newDeadline) {
		t.Fatalf("expected deadline %s, got %#v", newDeadline, updatedTask.Deadline)
	}

	if !updatedTask.UpdatedAt.After(oldUpdatedAt) {
		t.Fatalf("expected UpdatedAt to change, old %s, got %s", oldUpdatedAt, updatedTask.UpdatedAt)
	}
}

func TestTaskService_UpdateTaskClearDeadline(t *testing.T) {
	task := testTask(1, 10, domain.TaskStatusActive)
	deadline := time.Now().Add(24 * time.Hour)
	task.Deadline = &deadline
	repo := newFakeTaskRepository(task)
	service := NewTaskService(repo)

	updatedTask, err := service.UpdateTask(10, 1, UpdateTaskInput{
		ClearDeadline: true,
	})

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if updatedTask.Deadline != nil {
		t.Fatalf("expected deadline to be cleared, got %#v", updatedTask.Deadline)
	}

	if repo.saveCalls != 1 {
		t.Fatalf("expected Save to be called once, got %d", repo.saveCalls)
	}
}

func TestTaskService_UpdateTaskValidation(t *testing.T) {
	pastDeadline := time.Now().Add(-time.Hour)
	futureDeadline := time.Now().Add(24 * time.Hour)
	blankTitle := "   "
	invalidCategory := domain.TaskCategory("unknown")
	invalidPriority := domain.TaskPriority("urgent")
	invalidDifficulty := domain.TaskDifficulty("impossible")

	tests := []struct {
		name       string
		taskStatus domain.TaskStatus
		input      UpdateTaskInput
		wantErr    error
	}{
		{
			name:       "completed task cannot be updated",
			taskStatus: domain.TaskStatusCompleted,
			input:      UpdateTaskInput{Title: strPtr("New title")},
			wantErr:    ErrTaskCannotBeUpdated,
		},
		{
			name:       "cancelled task cannot be updated",
			taskStatus: domain.TaskStatusCancelled,
			input:      UpdateTaskInput{Title: strPtr("New title")},
			wantErr:    ErrTaskCannotBeUpdated,
		},
		{
			name:       "blank title",
			taskStatus: domain.TaskStatusActive,
			input:      UpdateTaskInput{Title: &blankTitle},
			wantErr:    ErrInvalidTitle,
		},
		{
			name:       "invalid category",
			taskStatus: domain.TaskStatusActive,
			input:      UpdateTaskInput{Category: &invalidCategory},
			wantErr:    ErrInvalidCategory,
		},
		{
			name:       "invalid priority",
			taskStatus: domain.TaskStatusActive,
			input:      UpdateTaskInput{Priority: &invalidPriority},
			wantErr:    ErrInvalidPriority,
		},
		{
			name:       "invalid difficulty",
			taskStatus: domain.TaskStatusActive,
			input:      UpdateTaskInput{Difficulty: &invalidDifficulty},
			wantErr:    ErrInvalidDifficulty,
		},
		{
			name:       "deadline conflict",
			taskStatus: domain.TaskStatusActive,
			input: UpdateTaskInput{
				ClearDeadline: true,
				Deadline:      &futureDeadline,
			},
			wantErr: ErrDeadlineConflict,
		},
		{
			name:       "past deadline",
			taskStatus: domain.TaskStatusActive,
			input:      UpdateTaskInput{Deadline: &pastDeadline},
			wantErr:    ErrInvalidDeadline,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := newFakeTaskRepository(testTask(1, 10, tt.taskStatus))
			service := NewTaskService(repo)

			task, err := service.UpdateTask(10, 1, tt.input)

			requireErrorIs(t, err, tt.wantErr)

			if task != nil {
				t.Fatalf("expected nil task, got %#v", task)
			}

			if repo.saveCalls != 0 {
				t.Fatalf("expected Save not to be called, got %d calls", repo.saveCalls)
			}
		})
	}
}

func TestTaskService_DeleteTask(t *testing.T) {
	tests := []struct {
		name        string
		task        *domain.Task
		userID      int64
		wantErr     error
		wantDeleted bool
	}{
		{
			name:        "deletes active task",
			task:        testTask(1, 10, domain.TaskStatusActive),
			userID:      10,
			wantDeleted: true,
		},
		{
			name:    "does not delete completed task",
			task:    testTask(1, 10, domain.TaskStatusCompleted),
			userID:  10,
			wantErr: ErrCompletedTaskCannotBeDeleted,
		},
		{
			name:    "does not delete another user's task",
			task:    testTask(1, 20, domain.TaskStatusActive),
			userID:  10,
			wantErr: ErrTaskNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := newFakeTaskRepository(tt.task)
			service := NewTaskService(repo)

			err := service.DeleteTask(tt.userID, tt.task.ID)

			if tt.wantErr != nil {
				requireErrorIs(t, err, tt.wantErr)
				if repo.deleteCalls != 0 {
					t.Fatalf("expected Delete not to be called, got %d calls", repo.deleteCalls)
				}
				return
			}

			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}

			if repo.deleteCalls != 1 {
				t.Fatalf("expected Delete to be called once, got %d", repo.deleteCalls)
			}

			if repo.deletedID != tt.task.ID {
				t.Fatalf("expected deleted id %d, got %d", tt.task.ID, repo.deletedID)
			}

			if _, ok := repo.tasks[tt.task.ID]; ok && tt.wantDeleted {
				t.Fatalf("expected task %d to be deleted", tt.task.ID)
			}
		})
	}
}

func TestTaskService_CompleteTask(t *testing.T) {
	oldUpdatedAt := time.Now().Add(-time.Hour)
	task := testTask(1, 10, domain.TaskStatusActive)
	task.UpdatedAt = oldUpdatedAt
	repo := newFakeTaskRepository(task)
	service := NewTaskService(repo)

	completedTask, err := service.CompleteTask(10, 1)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if completedTask.Status != domain.TaskStatusCompleted {
		t.Fatalf("expected status %q, got %q", domain.TaskStatusCompleted, completedTask.Status)
	}

	if completedTask.CompletedAt == nil {
		t.Fatal("expected CompletedAt to be set")
	}

	if !completedTask.UpdatedAt.After(oldUpdatedAt) {
		t.Fatalf("expected UpdatedAt to change, old %s, got %s", oldUpdatedAt, completedTask.UpdatedAt)
	}

	if repo.saveCalls != 1 {
		t.Fatalf("expected Save to be called once, got %d", repo.saveCalls)
	}
}

func TestTaskService_CompleteTaskAlreadyCompleted(t *testing.T) {
	repo := newFakeTaskRepository(testTask(1, 10, domain.TaskStatusCompleted))
	service := NewTaskService(repo)

	task, err := service.CompleteTask(10, 1)

	requireErrorIs(t, err, ErrTaskAlreadyCompleted)

	if task == nil {
		t.Fatal("expected existing task, got nil")
	}

	if repo.saveCalls != 0 {
		t.Fatalf("expected Save not to be called, got %d calls", repo.saveCalls)
	}
}
