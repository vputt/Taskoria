"""
API endpoints для работы с задачами
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status

from app.models.user import User
from app.schemas.task import (
    TaskCreate,
    TaskResponse,
    TaskWithSubtasks,
    TaskUpdate,
    TaskCompleteResponse
)
from app.schemas.subtask import SubtaskResponse
from app.services.task_service import TaskService, TaskSplitConflictError
from app.api.deps import get_current_user, get_task_service

router = APIRouter()


@router.get("", response_model=List[TaskResponse])
def get_tasks(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Получить список задач текущего пользователя.
    
    Args:
        skip: Количество пропускаемых записей
        limit: Максимальное количество записей
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        List[TaskResponse]: Список задач
    """
    tasks = task_service.get_user_tasks(current_user.id, skip, limit)
    return tasks


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_data: TaskCreate,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Создать новую задачу.
    
    Награды (XP и монеты) назначаются автоматически с помощью ИИ на основе сложности, времени выполнения и приоритета.
    
    Args:
        task_data: Данные задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        TaskResponse: Созданная задача с назначенными наградами
    """
    task = await task_service.create_task(
        current_user.id,
        task_data.model_dump()
    )
    return task


@router.get("/{task_id}", response_model=TaskWithSubtasks)
def get_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Получить задачу по ID с подзадачами.
    
    Args:
        task_id: ID задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        TaskWithSubtasks: Задача с подзадачами
    """
    try:
        task = task_service.get_task(task_id)
        
        # Проверка доступа
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this task"
            )
        
        return task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.patch("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    task_data: TaskUpdate,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Обновить задачу.
    
    Нельзя редактировать завершенные или отмененные задачи.
    
    Args:
        task_id: ID задачи
        task_data: Новые данные задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        TaskResponse: Обновленная задача
    """
    try:
        task = task_service.get_task(task_id)
        
        # Проверка доступа
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this task"
            )
        
        # Проверка статуса: нельзя редактировать завершенные или отмененные задачи
        if task.status.value in ["выполнена", "отменена"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot update task with status '{task.status.value}'. Only active or in-progress tasks can be updated."
            )
        
        updated_task = task_service.update_task(
            task_id,
            task_data.model_dump(exclude_unset=True)
        )
        return updated_task
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Удалить задачу.
    
    Нельзя удалять завершенные задачи (для сохранения статистики).
    Можно удалять активные, в процессе или отмененные задачи.
    
    Args:
        task_id: ID задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
    """
    try:
        task = task_service.get_task(task_id)
        
        # Проверка доступа
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this task"
            )
        
        # Проверка статуса: нельзя удалять завершенные задачи (сохраняем для статистики)
        if task.status.value == "выполнена":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete completed tasks. They are kept for statistics."
            )
        
        task_service.delete_task(task_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/{task_id}/complete", response_model=TaskCompleteResponse)
def complete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Завершить задачу (с начислением наград).
    
    Facade для сложной операции:
    - Обновление статуса
    - Обновление streak
    - Начисление наград
    - Публикация событий
    
    Args:
        task_id: ID задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        TaskCompleteResponse: Результат с наградами
    """
    try:
        task = task_service.get_task(task_id)
        
        # Проверка доступа
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to complete this task"
            )
        
        result = task_service.complete_task(task_id)
        
        return TaskCompleteResponse(
            task=result["task"],
            xp_earned=result["xp_earned"],
            coins_earned=result["coins_earned"],
            level_up=result["level_up"],
            new_level=result.get("new_level")
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/{task_id}/split", response_model=List[SubtaskResponse])
async def split_task(
    task_id: int,
    replace_existing: bool = False,
    current_user: User = Depends(get_current_user),
    task_service: TaskService = Depends(get_task_service)
):
    """
    Разбить задачу на подзадачи с помощью ИИ.
    
    Использует Strategy Pattern для выбора ИИ-провайдера (например, GigaChat).
    
    Args:
        task_id: ID задачи
        current_user: Текущий пользователь (DI)
        task_service: Сервис задач (DI)
        
    Returns:
        List[SubtaskResponse]: Созданные подзадачи
    """
    try:
        task = task_service.get_task(task_id)
        
        # Проверка доступа
        if task.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to modify this task"
            )
        
        subtasks = await task_service.split_task_with_ai(
            task_id,
            replace_existing=replace_existing
        )
        return subtasks
    except TaskSplitConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
