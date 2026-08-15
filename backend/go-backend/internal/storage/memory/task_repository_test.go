package memory

import (
	"testing"

	"taskoria-go/internal/domain"
	"taskoria-go/internal/service"
)

var _ service.TaskRepository = (*TaskRepository)(nil)

func TestTaskRepositoryCreate(t *testing.T) {
	repo := NewTaskRepository()
	first := testTask(10, "First task")
	second := testTask(20, "Second task")

	if err := repo.Create(first); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if err := repo.Create(second); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if first.ID != 1 {
		t.Fatalf("expected first task id 1, got %d", first.ID)
	}

	if second.ID != 2 {
		t.Fatalf("expected second task id 2, got %d", second.ID)
	}
}

func TestTaskRepositoryCreateNilTask(t *testing.T) {
	repo := NewTaskRepository()

	err := repo.Create(nil)

	requireErrorIs(t, err, ErrNilTask)
}

func TestTaskRepositoryGetByID(t *testing.T) {
	repo := NewTaskRepository()
	task := testTask(10, "Task")

	if err := repo.Create(task); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	foundTask, err := repo.GetByID(task.ID)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if foundTask == nil {
		t.Fatal("expected task, got nil")
	}

	if foundTask.ID != task.ID {
		t.Fatalf("expected task id %d, got %d", task.ID, foundTask.ID)
	}

	if foundTask.Title != task.Title {
		t.Fatalf("expected title %q, got %q", task.Title, foundTask.Title)
	}
}

func TestTaskRepositoryGetByIDNotFound(t *testing.T) {
	repo := NewTaskRepository()

	task, err := repo.GetByID(999)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if task != nil {
		t.Fatalf("expected nil task, got %#v", task)
	}
}

func TestTaskRepositoryGetByIDReturnsCopy(t *testing.T) {
	repo := NewTaskRepository()
	task := testTask(10, "Original title")

	if err := repo.Create(task); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	foundTask, err := repo.GetByID(task.ID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	foundTask.Title = "Changed without save"

	foundAgain, err := repo.GetByID(task.ID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if foundAgain.Title != "Original title" {
		t.Fatalf("expected repository state not to change without Save, got %q", foundAgain.Title)
	}
}

func TestTaskRepositoryListByUser(t *testing.T) {
	repo := NewTaskRepository()
	userTask := testTask(10, "User task")
	anotherUserTask := testTask(20, "Another user task")

	if err := repo.Create(userTask); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if err := repo.Create(anotherUserTask); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	tasks, err := repo.ListByUser(10)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(tasks) != 1 {
		t.Fatalf("expected 1 task, got %d", len(tasks))
	}

	if tasks[0].UserID != 10 {
		t.Fatalf("expected user id 10, got %d", tasks[0].UserID)
	}
}

func TestTaskRepositoryListByUserEmpty(t *testing.T) {
	repo := NewTaskRepository()

	tasks, err := repo.ListByUser(10)

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if tasks == nil {
		t.Fatal("expected empty slice, got nil")
	}

	if len(tasks) != 0 {
		t.Fatalf("expected empty slice, got %d tasks", len(tasks))
	}
}

func TestTaskRepositorySave(t *testing.T) {
	repo := NewTaskRepository()
	task := testTask(10, "Old title")

	if err := repo.Create(task); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	task.Title = "New title"

	if err := repo.Save(task); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	foundTask, err := repo.GetByID(task.ID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if foundTask.Title != "New title" {
		t.Fatalf("expected updated title, got %q", foundTask.Title)
	}
}

func TestTaskRepositorySaveErrors(t *testing.T) {
	tests := []struct {
		name    string
		task    *domain.Task
		wantErr error
	}{
		{
			name:    "nil task",
			task:    nil,
			wantErr: ErrNilTask,
		},
		{
			name:    "missing task",
			task:    &domain.Task{ID: 999},
			wantErr: ErrTaskNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := NewTaskRepository()

			err := repo.Save(tt.task)

			requireErrorIs(t, err, tt.wantErr)
		})
	}
}

func TestTaskRepositoryDelete(t *testing.T) {
	repo := NewTaskRepository()
	task := testTask(10, "Task")

	if err := repo.Create(task); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if err := repo.Delete(task.ID); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	foundTask, err := repo.GetByID(task.ID)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if foundTask != nil {
		t.Fatalf("expected task to be deleted, got %#v", foundTask)
	}
}

func TestTaskRepositoryDeleteNotFound(t *testing.T) {
	repo := NewTaskRepository()

	err := repo.Delete(999)

	requireErrorIs(t, err, ErrTaskNotFound)
}
