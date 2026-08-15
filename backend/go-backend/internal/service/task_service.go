package service

import (
	"strings"
	"time"

	"taskoria-go/internal/domain"
)

type TaskRepository interface {
	Create(task *domain.Task) error
	ListByUser(userID int64) ([]domain.Task, error)
	GetByID(id int64) (*domain.Task, error)
	Save(task *domain.Task) error
	Delete(id int64) error
}

type TaskService struct {
	tasks TaskRepository
}

func NewTaskService(tasks TaskRepository) *TaskService {
	return &TaskService{
		tasks: tasks,
	}
}

func (s *TaskService) CreateTask(userID int64, input CreateTaskInput) (*domain.Task, error) {
	now := time.Now()

	if err := validateCreateTaskInput(userID, input, now); err != nil {
		return nil, err
	}

	task := &domain.Task{
		UserID:      userID,
		Title:       strings.TrimSpace(input.Title),
		Description: input.Description,
		Category:    input.Category,
		Priority:    input.Priority,
		Difficulty:  input.Difficulty,
		Status:      domain.TaskStatusActive,
		XPReward:    10,
		CoinsReward: 100,
		CreatedAt:   now,
		UpdatedAt:   now,
		Deadline:    input.Deadline,
	}

	if err := s.tasks.Create(task); err != nil {
		return nil, err
	}

	return task, nil
}

func (s *TaskService) GetTask(userID int64, taskID int64) (*domain.Task, error) {
	task, err := s.tasks.GetByID(taskID)

	if err != nil {
		return nil, err
	}

	if task == nil {
		return nil, ErrTaskNotFound
	}

	if task.UserID != userID {
		return nil, ErrTaskNotFound
	}

	return task, nil
}

func (s *TaskService) ListTasks(userID int64) ([]domain.Task, error) {
	tasks, err := s.tasks.ListByUser(userID)
	if err != nil {
		return nil, err
	}

	return tasks, nil
}

func (s *TaskService) UpdateTask(userID int64, taskID int64, input UpdateTaskInput) (*domain.Task, error) {
	task, err := s.GetTask(userID, taskID)
	if err != nil {
		return nil, err
	}

	now := time.Now()

	if task.Status == domain.TaskStatusCompleted || task.Status == domain.TaskStatusCancelled {
		return nil, ErrTaskCannotBeUpdated
	}

	if err := validateUpdateTaskInput(input, now); err != nil {
		return nil, err
	}

	if input.Title != nil {
		task.Title = strings.TrimSpace(*input.Title)
	}

	if input.Description != nil {
		task.Description = *input.Description
	}

	if input.Category != nil {
		task.Category = *input.Category
	}

	if input.Priority != nil {
		task.Priority = *input.Priority
	}

	if input.Difficulty != nil {
		task.Difficulty = *input.Difficulty
	}

	if input.ClearDeadline {
		task.Deadline = nil
	} else if input.Deadline != nil {
		task.Deadline = input.Deadline
	}

	task.UpdatedAt = now

	if err := s.tasks.Save(task); err != nil {
		return nil, err
	}

	return task, nil
}

func (s *TaskService) DeleteTask(userID int64, taskID int64) error {
	task, err := s.GetTask(userID, taskID)
	if err != nil {
		return err
	}

	if task.Status == domain.TaskStatusCompleted {
		return ErrCompletedTaskCannotBeDeleted
	}

	return s.tasks.Delete(taskID)
}

func (s *TaskService) CompleteTask(userID int64, taskID int64) (*domain.Task, error) {
	task, err := s.GetTask(userID, taskID)
	if err != nil {
		return nil, err
	}

	if task.Status == domain.TaskStatusCompleted {
		return task, ErrTaskAlreadyCompleted
	}

	task.Complete()

	if err := s.tasks.Save(task); err != nil {
		return nil, err
	}

	return task, nil
}
