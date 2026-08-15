package httpapi

import (
	"errors"
	"net/http"
	"taskoria-go/internal/service"
)

func writeTaskServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrTaskNotFound):
		writeError(w, http.StatusNotFound, err.Error())

	case errors.Is(err, service.ErrInvalidUserID),
		errors.Is(err, service.ErrInvalidTitle),
		errors.Is(err, service.ErrInvalidCategory),
		errors.Is(err, service.ErrInvalidPriority),
		errors.Is(err, service.ErrInvalidDifficulty),
		errors.Is(err, service.ErrInvalidDeadline),
		errors.Is(err, service.ErrDeadlineConflict):
		writeError(w, http.StatusBadRequest, err.Error())

	case errors.Is(err, service.ErrTaskCannotBeUpdated),
		errors.Is(err, service.ErrTaskAlreadyCompleted),
		errors.Is(err, service.ErrCompletedTaskCannotBeDeleted):
		writeError(w, http.StatusConflict, err.Error())

	default:
		writeError(
			w,
			http.StatusInternalServerError,
			"internal server error",
		)
	}
}
