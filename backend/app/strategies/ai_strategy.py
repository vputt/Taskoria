"""
Strategy Pattern для ИИ-провайдеров (разбиение задач, оценка сложности и наград).

Паттерн: Strategy
Обоснование: Позволяет заменять ИИ-провайдера (GigaChat и др.) без изменения
бизнес-логики. Упрощает тестирование и расширение системы.
"""
from abc import ABC, abstractmethod
from typing import List, Dict
import logging
import json
import re

logger = logging.getLogger(__name__)


class AIStrategy(ABC):
    """
    Абстрактная стратегия для ИИ-провайдеров (Strategy Pattern).
    
    Применяемый паттерн: Strategy Pattern
    - Определяет семейство алгоритмов (разные ИИ-провайдеры: GigaChat, Mistral и др.)
    - Инкапсулирует каждый алгоритм
    - Делает алгоритмы взаимозаменяемыми
    
    Преимущества:
    - Легко добавить нового ИИ-провайдера
    - Можно менять провайдера во время выполнения
    - Упрощает тестирование (mock-стратегии)
    """
    
    @abstractmethod
    async def split_task(
        self, 
        task_description: str, 
        priority: str
    ) -> List[Dict[str, any]]:
        """
        Разбивает задачу на подзадачи с помощью ИИ.
        
        Args:
            task_description: Описание задачи
            priority: Приоритет задачи
            
        Returns:
            Список подзадач в формате:
            [
                {
                    "title": "Подзадача 1",
                    "description": "Описание",
                    "estimated_time": 30
                },
                ...
            ]
        """
        pass
    
    @abstractmethod
    async def estimate_difficulty(self, task_description: str) -> str:
        """
        Оценивает сложность задачи через внешний сервис.
        
        Args:
            task_description: Описание задачи
            
        Returns:
            Сложность: "легкая", "средняя" или "сложная"
        """
        pass
    
    @abstractmethod
    async def estimate_rewards(
        self,
        task_description: str,
        difficulty: str,
        estimated_time_minutes: int,
        priority: str
    ) -> dict:
        """
        Оценивает награды (XP и монеты) за задачу с помощью ИИ.
        
        ИИ анализирует описание задачи, сложность и время выполнения для назначения наград.
        
        Args:
            task_description: Описание задачи
            difficulty: Сложность задачи ("легкая", "средняя", "сложная")
            estimated_time_minutes: Примерное время выполнения в минутах
            priority: Приоритет задачи
            
        Returns:
            dict: {"xp": int, "coins": int} - награды за задачу
        """
        pass


class GigaChatStrategy(AIStrategy):
    """
    Стратегия для GigaChat API (ИИ для разбиения задач и оценки сложности).
    
    Реализует Strategy Pattern для работы с GigaChat через REST.
    """
    
    def __init__(self, authorization_key: str):
        """
        Инициализация стратегии GigaChat.
        
        Args:
            authorization_key: Ключ авторизации для получения Access token
        """
        self.authorization_key = authorization_key
        self._client = None
    
    async def _get_client(self):
        """Ленивая инициализация клиента (Lazy Loading)"""
        if self._client is None:
            try:
                from app.utils.gigachat_client import GigaChatClient
                self._client = GigaChatClient(
                    authorization_key=self.authorization_key
                )
            except Exception as e:
                logger.error(f"Failed to initialize GigaChat client: {e}")
                raise
        return self._client
    
    async def split_task(
        self, 
        task_description: str, 
        priority: str
    ) -> List[Dict[str, any]]:
        """
        Разбивает задачу на подзадачи через GigaChat API (ИИ).
        
        Args:
            task_description: Описание задачи
            priority: Приоритет задачи
            
        Returns:
            Список подзадач
        """
        try:
            client = await self._get_client()
            
            prompt = f"""Ты - эксперт по планированию и разбиению задач на конкретные выполнимые шаги.

Твоя задача: проанализировать описанную задачу и разбить её на логические, последовательные подзадачи.

Исходная задача: "{task_description}"
Приоритет: {priority}

сТРЕБОВАНИЯ К РАЗБИЕНИЮ:
1. Анализируй задачу глубоко - определи все необходимые этапы для её выполнения
2. Разбивай на конкретные, выполнимые шаги (не общие фразы типа "начать" или "завершить")
3. Подзадачи должны быть логически последовательными и взаимосвязанными
4. Каждая подзадача должна быть достаточно конкретной, чтобы её можно было выполнить
5. Учитывай приоритет при оценке времени и детализации
6. Количество подзадач: от 3 до 8 (в зависимости от сложности задачи)
7. Время должно быть реалистичным и соответствовать сложности подзадачи

ФОРМАТ ОТВЕТА (строго JSON массив):
[
  {{
    "title": "Конкретное название подзадачи (до 100 символов)",
    "description": "Детальное описание того, что нужно сделать (до 200 символов)",
    "estimated_time": число_в_минутах
  }},
  ...
]

ПРИМЕРЫ ХОРОШИХ ПОДЗАДАЧ:
- Для задачи "Изучить Python":
  * "Установить Python и настроить окружение" (15 мин)
  * "Изучить базовый синтаксис: переменные, типы данных" (60 мин)
  * "Практика: написать простые программы с условиями и циклами" (90 мин)
  * "Изучить работу с функциями и модулями" (45 мин)
  * "Создать финальный проект: калькулятор" (120 мин)

- Для задачи "Создать веб-сайт":
  * "Спроектировать структуру сайта и нарисовать макеты" (120 мин)
  * "Настроить HTML-разметку основных страниц" (90 мин)
  * "Добавить CSS стили и адаптивность" (150 мин)
  * "Реализовать интерактивность через JavaScript" (120 мин)
  * "Протестировать на разных устройствах и браузерах" (60 мин)

ВАЖНО:
- Избегай общих фраз: "Начать", "Завершить", "Продолжить"
- Используй конкретные действия: "Установить", "Написать", "Протестировать", "Настроить"
- В описании указывай ЧТО именно нужно сделать, а не просто название
- Время должно быть реалистичным (минимум 15 минут, максимум 240 минут на подзадачу)

Верни ТОЛЬКО JSON массив, без дополнительного текста, комментариев или пояснений."""

            messages = [
                {"role": "user", "content": prompt}
            ]
            
            response = await client.chat(messages)
            
            # Парсинг ответа
            subtasks = self._parse_response(response)
            logger.info(f"Task split into {len(subtasks)} subtasks")
            return subtasks
            
        except Exception as e:
            logger.error(f"Error splitting task with GigaChat: {e}")
            # Возвращаем минимальный результат в случае ошибки
            return self._get_fallback_subtasks(task_description)
    
    async def estimate_difficulty(self, task_description: str) -> str:
        """
        Оценивает сложность задачи через внешний API.
        
        Args:
            task_description: Описание задачи
            
        Returns:
            Сложность задачи
        """
        try:
            client = await self._get_client()
            
            prompt = f"""Оцени сложность следующей задачи.
Задача: {task_description}

Верни одно из значений: "легкая", "средняя", "сложная"
Верни только одно слово, без пояснений."""

            messages = [
                {"role": "user", "content": prompt}
            ]
            
            response = await client.chat(messages)
            difficulty = self._parse_difficulty(response)
            logger.info(f"Estimated difficulty: {difficulty}")
            return difficulty
            
        except Exception as e:
            logger.error(f"Error estimating difficulty with GigaChat: {e}")
            return "средняя"
    
    async def estimate_rewards(
        self,
        task_description: str,
        difficulty: str,
        estimated_time_minutes: int,
        priority: str
    ) -> dict:
        """
        Оценивает награды за задачу через GigaChat API (ИИ).
        
        ИИ анализирует задачу, сложность и время выполнения для назначения наград.
        
        Args:
            task_description: Описание задачи
            difficulty: Сложность задачи
            estimated_time_minutes: Примерное время выполнения в минутах
            priority: Приоритет задачи
            
        Returns:
            dict: {"xp": int, "coins": int} - награды за задачу
        """
        try:
            client = await self._get_client()
            
            prompt = f"""Ты - эксперт по геймификации и мотивации. Твоя задача - назначить справедливые награды за выполнение задачи.

Исходная задача: "{task_description}"
Сложность: {difficulty}
Примерное время выполнения: {estimated_time_minutes} минут
Приоритет: {priority}

ТРЕБОВАНИЯ К НАГРАДАМ:
1. Награды должны быть справедливыми и мотивирующими
2. Учитывай сложность задачи - сложные задачи дают больше наград
3. Учитывай время выполнения - длительные задачи дают больше наград
4. Учитывай приоритет - высокий приоритет дает небольшой бонус
5. Награды должны быть сбалансированными для игровой механики

ОГРАНИЧЕНИЯ (ВАЖНО!):
- XP: минимум 5, максимум 300
- Монеты: минимум 1, максимум 150
- Соотношение XP к монетам: примерно 2:1 (например, 100 XP = 50 монет)

ФОРМАТ ОТВЕТА (строго JSON):
{{
  "xp": число_от_5_до_300,
  "coins": число_от_1_до_150
}}

ПРИМЕРЫ:
- Легкая задача, 30 минут: {{"xp": 15, "coins": 8}}
- Средняя задача, 90 минут: {{"xp": 50, "coins": 25}}
- Сложная задача, 240 минут: {{"xp": 150, "coins": 75}}
- Очень сложная задача, 480 минут: {{"xp": 300, "coins": 150}}

Верни ТОЛЬКО JSON объект, без дополнительного текста."""

            messages = [
                {"role": "user", "content": prompt}
            ]
            
            response = await client.chat(messages)
            rewards = self._parse_rewards(response)
            
            # Применяем ограничения для безопасности
            rewards["xp"] = max(5, min(300, rewards.get("xp", 15)))
            rewards["coins"] = max(1, min(150, rewards.get("coins", 8)))
            
            logger.info(f"Estimated rewards: {rewards}")
            return rewards
            
        except Exception as e:
            logger.error(f"Error estimating rewards with GigaChat: {e}")
            # Fallback награды на основе сложности
            return self._get_fallback_rewards(difficulty, estimated_time_minutes)
    
    def _parse_rewards(self, response: dict) -> dict:
        """
        Парсит награды из ответа внешнего API.
        
        Args:
            response: Ответ от GigaChat API (dict)
            
        Returns:
            dict: {"xp": int, "coins": int}
        """
        try:
            choices = response.get("choices", [])
            if not choices:
                logger.warning("No choices in GigaChat response for rewards")
                return {"xp": 15, "coins": 8}
            
            text = choices[0].get("message", {}).get("content", "")
            
            if not text:
                logger.warning("Empty content in GigaChat response for rewards")
                return {"xp": 15, "coins": 8}
            
            # Ищем JSON объект в тексте
            json_match = re.search(r'\{[^}]*"xp"[^}]*"coins"[^}]*\}', text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
                rewards = json.loads(json_str)
                
                return {
                    "xp": int(rewards.get("xp", 15)),
                    "coins": int(rewards.get("coins", 8))
                }
            else:
                logger.warning("No JSON found in GigaChat response for rewards")
                return {"xp": 15, "coins": 8}
                
        except Exception as e:
            logger.error(f"Error parsing rewards: {e}")
            return {"xp": 15, "coins": 8}
    
    def _get_fallback_rewards(self, difficulty: str, estimated_time_minutes: int) -> dict:
        """
        Возвращает базовые награды на основе сложности и времени (fallback).
        
        Args:
            difficulty: Сложность задачи
            estimated_time_minutes: Примерное время выполнения
            
        Returns:
            dict: {"xp": int, "coins": int}
        """
        # Базовые награды на основе сложности
        base_rewards = {
            "легкая": {"xp": 10, "coins": 5},
            "средняя": {"xp": 30, "coins": 15},
            "сложная": {"xp": 80, "coins": 40}
        }
        
        base = base_rewards.get(difficulty.lower(), {"xp": 30, "coins": 15})
        
        # Учитываем время выполнения (примерно 1 XP за 3 минуты)
        time_bonus_xp = estimated_time_minutes // 3
        time_bonus_coins = estimated_time_minutes // 6
        
        xp = min(300, base["xp"] + time_bonus_xp)
        coins = min(150, base["coins"] + time_bonus_coins)
        
        return {"xp": max(5, xp), "coins": max(1, coins)}
    
    def _parse_response(self, response: dict) -> List[Dict[str, any]]:
        """
        Парсит ответ GigaChat.
        
        Args:
            response: Ответ от GigaChat API (dict)
            
        Returns:
            Список подзадач
        """
        try:
            # Извлекаем текст ответа из структуры API
            # GigaChat API возвращает: {"choices": [{"message": {"content": "..."}}]}
            choices = response.get("choices", [])
            if not choices:
                logger.warning("No choices in GigaChat response")
                return self._get_fallback_subtasks("")
            
            text = choices[0].get("message", {}).get("content", "")
            
            if not text:
                logger.warning("Empty content in GigaChat response")
                return self._get_fallback_subtasks("")
            
            # Ищем JSON массив в тексте
            json_match = re.search(r'\[.*\]', text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
                subtasks = json.loads(json_str)
                
                # Валидация и очистка
                validated_subtasks = []
                for i, subtask in enumerate(subtasks):
                    validated_subtasks.append({
                        "title": subtask.get("title", f"Подзадача {i+1}")[:100],
                        "description": subtask.get("description", "")[:200],
                        "estimated_time": int(subtask.get("estimated_time", 30)),
                        "order_index": i
                    })
                
                return validated_subtasks
            else:
                logger.warning("No JSON found in API response")
                return self._get_fallback_subtasks("")
                
        except Exception as e:
            logger.error(f"Error parsing GigaChat response: {e}")
            return self._get_fallback_subtasks("")
    
    def _parse_difficulty(self, response: dict) -> str:
        """
        Парсит оценку сложности из ответа GigaChat.
        
        Args:
            response: Ответ от GigaChat API (dict)
        
        Returns:
            Сложность задачи
        """
        try:
            # Извлекаем текст из структуры API
            choices = response.get("choices", [])
            if not choices:
                return "средняя"
            
            text = choices[0].get("message", {}).get("content", "").lower().strip()
            
            if "легк" in text:
                return "легкая"
            elif "сложн" in text or "трудн" in text:
                return "сложная"
            else:
                return "средняя"
                
        except Exception as e:
            logger.error(f"Error parsing difficulty: {e}")
            return "средняя"
    
    def _get_fallback_subtasks(self, task_description: str) -> List[Dict[str, any]]:
        """
        Возвращает базовые подзадачи, если ИИ недоступен или вернул ошибку.
        
        Args:
            task_description: Описание задачи
            
        Returns:
            Минимальный набор подзадач
        """
        return [
            {
                "title": "Начать выполнение задачи",
                "description": task_description[:200] if task_description else "Приступить к работе",
                "estimated_time": 30,
                "order_index": 0
            },
            {
                "title": "Завершить задачу",
                "description": "Проверить результат и завершить работу",
                "estimated_time": 15,
                "order_index": 1
            }
        ]


class MockAIStrategy(AIStrategy):
    """
    Mock-стратегия для тестов (не вызывает реальный ИИ).
    
    Используется в unit-тестах вместо реальных запросов к GigaChat API.
    """
    
    async def split_task(
        self, 
        task_description: str, 
        priority: str
    ) -> List[Dict[str, any]]:
        """Возвращает фиксированный набор подзадач для тестов"""
        return [
            {
                "title": "Подзадача 1",
                "description": "Тестовая подзадача 1",
                "estimated_time": 30,
                "order_index": 0
            },
            {
                "title": "Подзадача 2",
                "description": "Тестовая подзадача 2",
                "estimated_time": 45,
                "order_index": 1
            }
        ]
    
    async def estimate_difficulty(self, task_description: str) -> str:
        """Возвращает фиксированную сложность для тестов"""
        return "средняя"
    
    async def estimate_rewards(
        self,
        task_description: str,
        difficulty: str,
        estimated_time_minutes: int,
        priority: str
    ) -> dict:
        """Возвращает фиксированные награды для тестов"""
        return {"xp": 30, "coins": 15}
