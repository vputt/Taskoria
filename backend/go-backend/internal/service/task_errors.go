package service

import "errors"

var ErrInvalidUserID = errors.New("invalid user id")
var ErrInvalidTitle = errors.New("title is required")
var ErrInvalidCategory = errors.New("invalid task category")
var ErrInvalidPriority = errors.New("invalid task priority")
var ErrInvalidDifficulty = errors.New("invalid task difficulty")
var ErrTaskNotFound = errors.New("task not found")
var ErrInvalidDeadline = errors.New("deadline must be in the future")
var ErrDeadlineConflict = errors.New("deadline and clear deadline cannot be used together")
var ErrCompletedTaskCannotBeDeleted = errors.New("completed task cannot be deleted")
var ErrTaskAlreadyCompleted = errors.New("task already completed")
var ErrTaskCannotBeUpdated = errors.New("completed or cancelled task cannot be updated")
