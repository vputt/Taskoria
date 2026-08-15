package memory

import (
	"errors"
	"sync"
	"taskoria-go/internal/domain"
)

var ErrNilTask = errors.New("task is nil")
var ErrTaskNotFound = errors.New("task not found")

type TaskRepository struct {
	mux    sync.RWMutex
	nextID int64
	tasks  map[int64]domain.Task
}

func NewTaskRepository() *TaskRepository {
	return &TaskRepository{
		tasks: make(map[int64]domain.Task),
	}
}

func (r *TaskRepository) Create(task *domain.Task) error {
	if task == nil {
		return ErrNilTask
	}

	r.mux.Lock()
	defer r.mux.Unlock()

	r.nextID++
	task.ID = r.nextID
	r.tasks[task.ID] = *task

	return nil
}

func (r *TaskRepository) GetByID(taskID int64) (*domain.Task, error) {
	r.mux.RLock()
	defer r.mux.RUnlock()

	task, ok := r.tasks[taskID]

	if !ok {
		return nil, nil
	}

	return &task, nil
}

func (r *TaskRepository) ListByUser(userID int64) ([]domain.Task, error) {
	list := make([]domain.Task, 0)

	r.mux.RLock()
	defer r.mux.RUnlock()

	for _, v := range r.tasks {
		if v.UserID != userID {
			continue
		}

		list = append(list, v)
	}

	return list, nil
}

func (r *TaskRepository) Save(task *domain.Task) error {
	if task == nil {
		return ErrNilTask
	}

	r.mux.Lock()
	defer r.mux.Unlock()

	if _, ok := r.tasks[task.ID]; !ok {
		return ErrTaskNotFound
	}
	r.tasks[task.ID] = *task

	return nil
}

func (r *TaskRepository) Delete(taskID int64) error {
	r.mux.Lock()
	defer r.mux.Unlock()

	if _, ok := r.tasks[taskID]; !ok {
		return ErrTaskNotFound
	}

	delete(r.tasks, taskID)

	return nil
}
