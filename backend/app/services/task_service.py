"""
Сервис управления задачами
"""
from typing import List
from datetime import date

from app.models.task import Task
from app.models.subtask import Subtask
from app.repositories.task_repository import TaskRepository
from app.repositories.subtask_repository import SubtaskRepository
from app.services.ai_service import AIService
from app.services.reward_service import RewardService
from app.states.streak_state import StreakManager
from app.core.event_bus import EventBus, EventType
from app.repositories.user_repository import UserRepository


class TaskService:
    """
    Сервис управления задачами (с применением множества паттернов).
    
    Применяемые паттерны:
    - Dependency Injection: внедрение зависимостей
    - Facade: упрощение сложных операций
    - Observer: публикация событий
    - State: управление streak
    """
    
    def __init__(
        self,
        task_repo: TaskRepository,
        subtask_repo: SubtaskRepository,
        user_repo: UserRepository,
        ai_service: AIService,
        reward_service: RewardService,
        event_bus: EventBus
    ):
        """
        Инициализация сервиса (Dependency Injection).
        
        Args:
            task_repo: Репозиторий задач
            subtask_repo: Репозиторий подзадач
            user_repo: Репозиторий пользователей
            ai_service: ИИ-сервис (разбиение задач, оценка сложности и наград)
            reward_service: Сервис наград
            event_bus: Шина событий
        """
        self.task_repo = task_repo
        self.subtask_repo = subtask_repo
        self.user_repo = user_repo
        self.ai_service = ai_service
        self.reward_service = reward_service
        self.event_bus = event_bus
        self.streak_manager = StreakManager()
    
    async def create_task(self, user_id: int, task_data: dict) -> Task:
        """
        Создаёт задачу с оценкой наград через ИИ.
        
        ИИ анализирует задачу и назначает награды на основе сложности, времени выполнения и приоритета.
        
        Args:
            user_id: ID пользователя
            task_data: Данные задачи
            
        Returns:
            Task: Созданная задача
        """
        task_data["user_id"] = user_id
        
        # Если награды не указаны, вычисляем их через ИИ
        if "xp_reward" not in task_data or "coins_reward" not in task_data:
            try:
                task_description = task_data.get("description") or task_data.get("title", "")
                
                # Определяем сложность: используем указанную или оцениваем через AI
                if "difficulty" in task_data and task_data["difficulty"]:
                    # Используем указанную пользователем сложность
                    from app.models.task import TaskDifficulty
                    difficulty_enum = task_data["difficulty"]
                    if isinstance(difficulty_enum, TaskDifficulty):
                        difficulty_str = difficulty_enum.value
                    else:
                        difficulty_str = str(difficulty_enum)
                    
                    # Конвертируем в формат для ИИ
                    difficulty_map = {
                        "легкая": "легкая",
                        "easy": "легкая",
                        "средняя": "средняя",
                        "medium": "средняя",
                        "сложная": "сложная",
                        "hard": "сложная"
                    }
                    difficulty = difficulty_map.get(difficulty_str.lower(), "средняя")
                else:
                    # Оцениваем сложность через ИИ
                    difficulty = await self.ai_service.estimate_difficulty(task_description)
                    
                    # Сохраняем оценку ИИ в task_data
                    from app.models.task import TaskDifficulty
                    difficulty_map = {
                        "легкая": TaskDifficulty.EASY,
                        "средняя": TaskDifficulty.MEDIUM,
                        "сложная": TaskDifficulty.HARD
                    }
                    task_data["difficulty"] = difficulty_map.get(difficulty.lower(), TaskDifficulty.MEDIUM)
                
                # Оцениваем примерное время выполнения
                # Если есть подзадачи, суммируем их время, иначе используем оценку по умолчанию
                estimated_time = task_data.get("estimated_time_minutes", 60)  # По умолчанию 60 минут
                
                # Оцениваем награды через ИИ
                priority = task_data.get("priority", "средняя")
                if hasattr(priority, 'value'):
                    priority = priority.value
                
                rewards = await self.ai_service.estimate_rewards(
                    task_description=task_description,
                    difficulty=difficulty,
                    estimated_time_minutes=estimated_time,
                    priority=priority
                )
                
                task_data["xp_reward"] = rewards["xp"]
                task_data["coins_reward"] = rewards["coins"]
                
            except Exception as e:
                # Fallback награды в случае ошибки AI
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Failed to estimate rewards with AI: {e}, using defaults")
                task_data.setdefault("xp_reward", 15)
                task_data.setdefault("coins_reward", 8)
        
        task = self.task_repo.create(task_data)
        
        # Публикуем событие создания задачи
        self.event_bus.publish(EventType.TASK_CREATED, {
            "user_id": user_id,
            "task_id": task.id,
            "category": task.category.value
        })
        
        return task
    
    async def split_task_with_ai(self, task_id: int) -> List[Subtask]:
        """
        Разбивает задачу на подзадачи с помощью ИИ (Facade).
        
        После разбиения пересчитывает награды на основе суммарного времени подзадач.
        
        Args:
            task_id: ID задачи
            
        Returns:
            List[Subtask]: Созданные подзадачи
        """
        # Получаем задачу
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")
        
        # Разбиваем через AI
        subtasks_data = await self.ai_service.split_task(
            task.description or task.title,
            task.priority.value
        )
        
        # Создаем подзадачи
        subtasks = []
        total_time = 0
        for subtask_data in subtasks_data:
            estimated_time = subtask_data.get("estimated_time", 30)
            total_time += estimated_time
            
            subtask = self.subtask_repo.create({
                "task_id": task_id,
                "title": subtask_data["title"],
                "description": subtask_data.get("description", ""),
                "estimated_time": estimated_time,
                "order_index": subtask_data.get("order_index", len(subtasks))
            })
            subtasks.append(subtask)
        
        # Пересчитываем награды на основе суммарного времени подзадач
        if subtasks and total_time > 0:
            try:
                task_description = task.description or task.title
                difficulty = task.difficulty.value if task.difficulty else "средняя"
                priority = task.priority.value
                
                # Конвертируем сложность в формат для ИИ
                difficulty_map = {
                    "легкая": "легкая",
                    "easy": "легкая",
                    "средняя": "средняя",
                    "medium": "средняя",
                    "сложная": "сложная",
                    "hard": "сложная"
                }
                difficulty_str = difficulty_map.get(difficulty.lower(), "средняя")
                
                # Пересчитываем награды через ИИ
                rewards = await self.ai_service.estimate_rewards(
                    task_description=task_description,
                    difficulty=difficulty_str,
                    estimated_time_minutes=total_time,
                    priority=priority
                )
                
                # Обновляем награды задачи
                task.xp_reward = rewards["xp"]
                task.coins_reward = rewards["coins"]
                self.task_repo.update(task, {})
                
            except Exception as e:
                # Логируем ошибку, но не прерываем выполнение
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Failed to recalculate rewards after splitting: {e}")
        
        return subtasks
    
    def complete_task(self, task_id: int) -> dict:
        """
        Завершает задачу (Facade для сложной операции).
        
        Выполняет:
        1. Обновление статуса задачи
        2. Обновление streak
        3. Начисление наград
        4. Публикацию событий
        
        Args:
            task_id: ID задачи
            
        Returns:
            dict: Результат с информацией о наградах
        """
        # Получаем задачу
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")
        
        if task.status.value == "выполнена":
            raise ValueError("Task already completed")
        
        # Завершаем задачу
        task.complete()
        self.task_repo.update(task, {})
        
        # Получаем пользователя
        user = self.user_repo.get(task.user_id)
        
        # Обновляем streak (State Pattern)
        old_streak = user.streak
        new_streak = self.streak_manager.update_streak(user, date.today())
        self.user_repo.update(user, {})
        
        # Публикуем событие обновления streak
        if new_streak != old_streak:
            self.event_bus.publish(EventType.STREAK_UPDATED, {
                "user_id": user.id,
                "old_streak": old_streak,
                "new_streak": new_streak
            })
        
        # Подсчитываем подзадачи
        subtasks = self.subtask_repo.get_by_task(task_id)
        
        # Начисляем награды (Template Method + Observer)
        reward_result = self.reward_service.calculate_and_apply_rewards(
            user_id=task.user_id,
            task_description=task.description or task.title,
            priority=task.priority.value,
            subtasks_count=len(subtasks),
            category=task.category.value
        )
        
        # Публикуем событие завершения задачи (Observer)
        self.event_bus.publish(EventType.TASK_COMPLETED, {
            "user_id": task.user_id,
            "task_id": task.id,
            "task": task,
            "user": user,
            "xp_earned": reward_result["xp_earned"],
            "coins_earned": reward_result["coins_earned"]
        })
        
        return {
            "task": task,
            "streak": new_streak,
            **reward_result
        }
    
    def get_user_tasks(
        self,
        user_id: int,
        skip: int = 0,
        limit: int = 100
    ) -> List[Task]:
        """
        Получает задачи пользователя.
        
        Args:
            user_id: ID пользователя
            skip: Количество пропускаемых записей
            limit: Максимальное количество записей
            
        Returns:
            List[Task]: Список задач
        """
        return self.task_repo.get_by_user(user_id, skip, limit)
    
    def get_task(self, task_id: int) -> Task:
        """
        Получает задачу по ID.
        
        Args:
            task_id: ID задачи
            
        Returns:
            Task: Задача
            
        Raises:
            ValueError: Если задача не найдена
        """
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")
        return task
    
    def update_task(self, task_id: int, task_data: dict) -> Task:
        """
        Обновляет задачу.
        
        Args:
            task_id: ID задачи
            task_data: Новые данные задачи
            
        Returns:
            Task: Обновленная задача
        """
        task = self.get_task(task_id)
        return self.task_repo.update(task, task_data)
    
    def delete_task(self, task_id: int) -> bool:
        """
        Удаляет задачу.
        
        Args:
            task_id: ID задачи
            
        Returns:
            bool: True если удалена
        """
        result = self.task_repo.delete(task_id)
        
        if result:
            self.event_bus.publish(EventType.TASK_DELETED, {
                "task_id": task_id
            })
        
        return result
