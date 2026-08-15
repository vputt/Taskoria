package service

import "taskoria-go/internal/domain"

type fakeTaskRepository struct {
	tasks map[int64]*domain.Task

	createErr error
	listErr   error
	getErr    error
	saveErr   error
	deleteErr error

	createCalls int
	listCalls   int
	getCalls    int
	saveCalls   int
	deleteCalls int

	nextID      int64
	createdTask *domain.Task
	savedTask   *domain.Task
	deletedID   int64
}

func newFakeTaskRepository(tasks ...*domain.Task) *fakeTaskRepository {
	repo := &fakeTaskRepository{
		tasks:  make(map[int64]*domain.Task),
		nextID: 100,
	}

	for _, task := range tasks {
		copied := *task
		repo.tasks[copied.ID] = &copied
		if copied.ID > repo.nextID {
			repo.nextID = copied.ID
		}
	}

	return repo
}

func (r *fakeTaskRepository) Create(task *domain.Task) error {
	r.createCalls++
	r.createdTask = task

	if r.createErr != nil {
		return r.createErr
	}

	if task.ID == 0 {
		r.nextID++
		task.ID = r.nextID
	}

	copied := *task
	r.tasks[task.ID] = &copied

	return nil
}

func (r *fakeTaskRepository) ListByUser(userID int64) ([]domain.Task, error) {
	r.listCalls++

	if r.listErr != nil {
		return nil, r.listErr
	}

	tasks := make([]domain.Task, 0)
	for _, task := range r.tasks {
		if task.UserID == userID {
			tasks = append(tasks, *task)
		}
	}

	return tasks, nil
}

func (r *fakeTaskRepository) GetByID(id int64) (*domain.Task, error) {
	r.getCalls++

	if r.getErr != nil {
		return nil, r.getErr
	}

	task, ok := r.tasks[id]
	if !ok {
		return nil, nil
	}

	return task, nil
}

func (r *fakeTaskRepository) Save(task *domain.Task) error {
	r.saveCalls++
	r.savedTask = task

	if r.saveErr != nil {
		return r.saveErr
	}

	copied := *task
	r.tasks[task.ID] = &copied

	return nil
}

func (r *fakeTaskRepository) Delete(id int64) error {
	r.deleteCalls++
	r.deletedID = id

	if r.deleteErr != nil {
		return r.deleteErr
	}

	delete(r.tasks, id)

	return nil
}
