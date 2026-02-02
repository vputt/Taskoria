"""
API endpoints для работы с подзадачами
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status

from app.models.user import User
from app.models.subtask import SubtaskStatus
from app.schemas.subtask import (
    SubtaskCreate,
    SubtaskResponse,
    SubtaskUpdate
)
from app.api.deps import (
    get_current_user,
    get_subtask_repo,
    get_task_repo
)
from app.repositories.subtask_repository import SubtaskRepository
from app.repositories.task_repository import TaskRepository

router = APIRouter()


@router.get("", response_model=List[SubtaskResponse])
def get_subtasks(
    task_id: int,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Получить список подзадач для задачи.
    
    Args:
        task_id: ID задачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
        
    Returns:
        List[SubtaskResponse]: Список подзадач
    """
    # Проверяем доступ к задаче
    task = task_repo.get(task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this task"
        )
    
    subtasks = subtask_repo.get_by_task(task_id)
    return subtasks


@router.post("", response_model=SubtaskResponse, status_code=status.HTTP_201_CREATED)
def create_subtask(
    task_id: int,
    subtask_data: SubtaskCreate,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Создать новую подзадачу.
    
    Нельзя создавать подзадачи для завершенных или отмененных задач.
    
    Args:
        task_id: ID задачи
        subtask_data: Данные подзадачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
        
    Returns:
        SubtaskResponse: Созданная подзадача
    """
    # Проверяем доступ к задаче
    task = task_repo.get(task_id)
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found"
        )
    
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create subtasks for this task"
        )
    
    # Проверка статуса задачи
    if task.status.value in ["выполнена", "отменена"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot create subtasks for task with status '{task.status.value}'"
        )
    
    # Создаем подзадачу
    subtask_dict = subtask_data.model_dump()
    subtask_dict["task_id"] = task_id
    
    # Если order_index не указан, ставим в конец
    if "order_index" not in subtask_dict or subtask_dict["order_index"] is None:
        existing_subtasks = subtask_repo.get_by_task(task_id)
        subtask_dict["order_index"] = len(existing_subtasks)
    
    subtask = subtask_repo.create(subtask_dict)
    return subtask


@router.patch("/{subtask_id}", response_model=SubtaskResponse)
def update_subtask(
    subtask_id: int,
    subtask_data: SubtaskUpdate,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Обновить подзадачу.
    
    Нельзя редактировать подзадачи завершенных или отмененных задач.
    Нельзя редактировать выполненные подзадачи.
    
    Args:
        subtask_id: ID подзадачи
        subtask_data: Новые данные подзадачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
        
    Returns:
        SubtaskResponse: Обновленная подзадача
    """
    # Получаем подзадачу
    subtask = subtask_repo.get(subtask_id)
    if not subtask:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subtask not found"
        )
    
    # Проверяем доступ к задаче
    task = task_repo.get(subtask.task_id)
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this subtask"
        )
    
    # Проверка статуса задачи
    if task.status.value in ["выполнена", "отменена"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot update subtask of task with status '{task.status.value}'"
        )
    
    # Проверка статуса подзадачи
    if subtask.status.value == "выполнена":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot update completed subtask"
        )
    
    # Обновляем подзадачу
    updated_subtask = subtask_repo.update(
        subtask,
        subtask_data.model_dump(exclude_unset=True)
    )
    return updated_subtask


@router.post("/{subtask_id}/complete", response_model=SubtaskResponse)
def complete_subtask(
    subtask_id: int,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Отметить подзадачу как выполненную.
    
    Можно завершать только подзадачи активных задач или задач в процессе.
    
    Args:
        subtask_id: ID подзадачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
        
    Returns:
        SubtaskResponse: Обновленная подзадача
    """
    # Получаем подзадачу
    subtask = subtask_repo.get(subtask_id)
    if not subtask:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subtask not found"
        )
    
    # Проверяем доступ к задаче
    task = task_repo.get(subtask.task_id)
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to complete this subtask"
        )
    
    # Проверка статуса задачи
    if task.status.value in ["выполнена", "отменена"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot complete subtask of task with status '{task.status.value}'"
        )
    
    # Завершаем подзадачу
    subtask.complete()
    subtask_repo.update(subtask, {})
    
    return subtask


@router.post("/{subtask_id}/start", response_model=SubtaskResponse)
def start_subtask(
    subtask_id: int,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Начать выполнение подзадачи.
    
    Можно начинать только подзадачи активных задач или задач в процессе.
    
    Args:
        subtask_id: ID подзадачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
        
    Returns:
        SubtaskResponse: Обновленная подзадача
    """
    # Получаем подзадачу
    subtask = subtask_repo.get(subtask_id)
    if not subtask:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subtask not found"
        )
    
    # Проверяем доступ к задаче
    task = task_repo.get(subtask.task_id)
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to start this subtask"
        )
    
    # Проверка статуса задачи
    if task.status.value in ["выполнена", "отменена"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot start subtask of task with status '{task.status.value}'"
        )
    
    # Начинаем подзадачу
    subtask.start()
    subtask_repo.update(subtask, {})
    
    return subtask


@router.delete("/{subtask_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subtask(
    subtask_id: int,
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo)
):
    """
    Удалить подзадачу.
    
    Нельзя удалять подзадачи завершенных задач (для сохранения статистики).
    Нельзя удалять выполненные подзадачи (для сохранения статистики).
    
    Args:
        subtask_id: ID подзадачи
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        subtask_repo: Репозиторий подзадач (DI)
    """
    # Получаем подзадачу
    subtask = subtask_repo.get(subtask_id)
    if not subtask:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subtask not found"
        )
    
    # Проверяем доступ к задаче
    task = task_repo.get(subtask.task_id)
    if task.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this subtask"
        )
    
    # Проверка статуса задачи
    if task.status.value == "выполнена":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete subtasks of completed task. They are kept for statistics."
        )
    
    # Проверка статуса подзадачи
    if subtask.status.value == "выполнена":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete completed subtask. It is kept for statistics."
        )
    
    # Удаляем подзадачу
    subtask_repo.delete(subtask_id)
