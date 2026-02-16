import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/repository_contracts.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class MockAppStore {
  MockAppStore({
    required this.user,
    required this.tasks,
    required this.cityState,
    required this.achievementProgress,
    required this.shopItems,
    required this.completedByCategory,
  });

  factory MockAppStore.seeded() {
    return MockAppStore(
      user: buildMockUserProfile(),
      tasks: buildMockTasks(),
      cityState: buildMockCityState(),
      achievementProgress: buildMockAchievementProgress(),
      shopItems: buildMockShopItems(),
      completedByCategory: buildMockCompletedCategoryCounters(),
    );
  }

  UserProfile user;
  List<TaskWithSubtasks> tasks;
  CityState cityState;
  List<AchievementProgress> achievementProgress;
  List<ShopItem> shopItems;
  Map<TaskCategory, int> completedByCategory;
}

class MockUserRepository implements UserRepository {
  const MockUserRepository(this.store);

  final MockAppStore store;

  @override
  Future<UserProfile> getCurrentUser() async => store.user;
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.store, this.storage);

  final MockAppStore store;
  final SessionStorage storage;

  @override
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    store.user = store.user.copyWith(email: email, username: username);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await storage.writeToken('mock-session-token');
    store.user = store.user.copyWith(email: email);
    return AuthSession(token: 'mock-session-token', user: store.user);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final String? token = await storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return AuthSession(token: token, user: store.user);
  }

  @override
  Future<void> logout() => storage.clearToken();
}

class MockTaskRepository implements TaskRepository {
  MockTaskRepository(this.store);

  final MockAppStore store;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskCategory? category,
  }) async {
    Iterable<TaskWithSubtasks> data = store.tasks;

    if (status != null) {
      data = data.where((TaskWithSubtasks item) => item.status == status);
    }
    if (category != null) {
      data = data.where((TaskWithSubtasks item) => item.category == category);
    }

    final List<Task> items = data
        .map((TaskWithSubtasks item) => item.toTask())
        .toList(growable: false);
    items.sort((Task a, Task b) {
      final DateTime aDate = a.deadline ?? a.createdAt;
      final DateTime bDate = b.deadline ?? b.createdAt;
      return aDate.compareTo(bDate);
    });
    return items;
  }

  @override
  Future<TaskWithSubtasks> getTask(int taskId) async {
    return _requireTask(taskId);
  }

  @override
  Future<Task> createTask(TaskCreateInput input) async {
    final int nextId =
        store.tasks.fold<int>(
          100,
          (int current, TaskWithSubtasks task) =>
              task.id > current ? task.id : current,
        ) +
        1;
    final DateTime now = DateTime(2026, 3, 31, 15);
    final TaskDifficulty difficulty = input.difficulty ?? TaskDifficulty.medium;
    final TaskWithSubtasks task = TaskWithSubtasks(
      id: nextId,
      userId: store.user.id,
      title: input.title,
      description: input.description,
      category: input.category,
      priority: input.priority,
      deadline: input.deadline,
      status: TaskStatus.active,
      difficulty: difficulty,
      xpReward: _xpRewardFor(difficulty),
      coinsReward: _coinRewardFor(difficulty),
      subtasks: const <Subtask>[],
      createdAt: now,
      completedAt: null,
      updatedAt: now,
    );

    store.tasks = <TaskWithSubtasks>[task, ...store.tasks];
    return task.toTask();
  }

  @override
  Future<Task> updateTask(int taskId, TaskUpdateInput input) async {
    final int index = store.tasks.indexWhere(
      (TaskWithSubtasks item) => item.id == taskId,
    );
    final TaskWithSubtasks current = _requireTask(taskId);
    final TaskDifficulty difficulty = input.difficulty ?? current.difficulty;
    final TaskWithSubtasks updated = current.copyWith(
      title: input.title ?? current.title,
      description: input.description ?? current.description,
      category: input.category ?? current.category,
      priority: input.priority ?? current.priority,
      difficulty: difficulty,
      xpReward: _xpRewardFor(difficulty),
      coinsReward: _coinRewardFor(difficulty),
      deadline: input.clearDeadline
          ? null
          : (input.deadline ?? current.deadline),
      status: input.status ?? current.status,
      updatedAt: DateTime(2026, 3, 31, 15, 10),
    );
    store.tasks[index] = updated;
    return updated.toTask();
  }

  @override
  Future<void> deleteTask(int taskId) async {
    store.tasks = store.tasks
        .where((TaskWithSubtasks item) => item.id != taskId)
        .toList(growable: false);
  }

  @override
  Future<TaskCompleteResult> completeTask(int taskId) async {
    final int index = store.tasks.indexWhere(
      (TaskWithSubtasks item) => item.id == taskId,
    );
    final TaskWithSubtasks current = _requireTask(taskId);
    if (current.status == TaskStatus.completed) {
      return TaskCompleteResult(
        task: current.toTask(),
        xpEarned: 0,
        coinsEarned: 0,
        levelUp: false,
        newLevel: store.user.level,
        streak: store.user.streak,
      );
    }

    final DateTime completedAt = DateTime(2026, 3, 31, 20);
    final TaskWithSubtasks completedTask = current.copyWith(
      status: TaskStatus.completed,
      completedAt: completedAt,
      updatedAt: completedAt,
      subtasks: current.subtasks
          .map(
            (Subtask subtask) => subtask.status == SubtaskStatus.completed
                ? subtask
                : subtask.copyWith(status: SubtaskStatus.completed),
          )
          .toList(growable: false),
    );
    store.tasks[index] = completedTask;

    final int oldLevel = store.user.level;
    final int nextXp = store.user.xp + current.xpReward;
    final int nextLevel = (nextXp ~/ xpPerLevel) + 1;
    final int nextStreak = store.user.streak + 1;

    store.user = store.user.copyWith(
      xp: nextXp,
      coins: store.user.coins + current.coinsReward,
      level: nextLevel,
      streak: nextStreak,
      lastActivityDate: completedAt,
      xpToNextLevel: (nextLevel * xpPerLevel) - nextXp,
      tasksCompleted: store.user.tasksCompleted + 1,
    );

    store.completedByCategory = <TaskCategory, int>{
      ...store.completedByCategory,
      current.category: (store.completedByCategory[current.category] ?? 0) + 1,
    };
    _syncCityForCategory(current.category, completedAt);
    _refreshAchievementProgress();

    return TaskCompleteResult(
      task: completedTask.toTask(),
      xpEarned: current.xpReward,
      coinsEarned: current.coinsReward,
      levelUp: nextLevel > oldLevel,
      newLevel: nextLevel,
      streak: nextStreak,
    );
  }

  @override
  Future<List<Subtask>> splitTask(
    int taskId, {
    bool replaceExisting = false,
  }) async {
    final int index = store.tasks.indexWhere(
      (TaskWithSubtasks item) => item.id == taskId,
    );
    final TaskWithSubtasks current = _requireTask(taskId);
    if (current.subtasks.isNotEmpty && !replaceExisting) {
      throw const SubtasksAlreadyExistException();
    }

    final List<Subtask> generated = <Subtask>[
      Subtask(
        id: 5000 + taskId * 10,
        taskId: taskId,
        title: 'Разобрать задачу на этапы',
        description: 'Сформулировать 2-3 ключевых шага.',
        estimatedTime: 20,
        status: SubtaskStatus.notStarted,
        orderIndex: 0,
      ),
      Subtask(
        id: 5001 + taskId * 10,
        taskId: taskId,
        title: 'Сделать основной блок работы',
        estimatedTime: 45,
        status: SubtaskStatus.notStarted,
        orderIndex: 1,
      ),
      Subtask(
        id: 5002 + taskId * 10,
        taskId: taskId,
        title: 'Проверить результат и закрыть',
        estimatedTime: 15,
        status: SubtaskStatus.notStarted,
        orderIndex: 2,
      ),
    ];

    store.tasks[index] = current.copyWith(
      subtasks: generated,
      updatedAt: DateTime(2026, 3, 31, 15, 20),
    );
    return generated;
  }

  @override
  Future<Subtask> updateSubtask(
    int taskId,
    int subtaskId,
    SubtaskUpdateInput input,
  ) async {
    final int taskIndex = store.tasks.indexWhere(
      (TaskWithSubtasks item) => item.id == taskId,
    );
    final TaskWithSubtasks task = _requireTask(taskId);
    final List<Subtask> updated = task.subtasks
        .map((Subtask subtask) {
          if (subtask.id != subtaskId) {
            return subtask;
          }
          return subtask.copyWith(
            title: input.title ?? subtask.title,
            description: input.description ?? subtask.description,
            estimatedTime: input.estimatedTime ?? subtask.estimatedTime,
            status: input.status ?? subtask.status,
            orderIndex: input.orderIndex ?? subtask.orderIndex,
          );
        })
        .toList(growable: false);
    final Subtask result = updated.firstWhere(
      (Subtask item) => item.id == subtaskId,
    );
    store.tasks[taskIndex] = task.copyWith(
      subtasks: updated,
      updatedAt: DateTime(2026, 3, 31, 15, 25),
    );
    return result;
  }

  TaskWithSubtasks _requireTask(int taskId) {
    return store.tasks.firstWhere((TaskWithSubtasks item) => item.id == taskId);
  }

  int _xpRewardFor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 60;
      case TaskDifficulty.medium:
        return 120;
      case TaskDifficulty.hard:
        return 180;
    }
  }

  int _coinRewardFor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 20;
      case TaskDifficulty.medium:
        return 40;
      case TaskDifficulty.hard:
        return 60;
    }
  }

  void _syncCityForCategory(TaskCategory category, DateTime now) {
    final int count = store.completedByCategory[category] ?? 0;
    final int level = _resolveBuildingLevel(count);
    final List<Building> buildings = store.cityState.response.buildings
        .map((Building building) {
          if (building.category != category) {
            return building;
          }
          return building.copyWith(level: level, upgradedAt: now);
        })
        .toList(growable: false);
    final int totalLevel = buildings.fold<int>(
      0,
      (int value, Building item) => value + item.level,
    );

    store.cityState = store.cityState.copyWith(
      response: store.cityState.response.copyWith(
        buildings: buildings,
        totalLevel: totalLevel,
        averageLevel: totalLevel / buildings.length,
      ),
    );
    store.user = store.user.copyWith(buildingsCount: buildings.length);
  }

  int _resolveBuildingLevel(int count) {
    if (count >= 3) {
      return 3;
    }
    if (count >= 2) {
      return 2;
    }
    return 1;
  }

  void _refreshAchievementProgress() {
    final int completedTasks = store.user.tasksCompleted;
    final int streak = store.user.streak;
    final int buildings = store.cityState.response.totalBuildings;

    store.achievementProgress = store.achievementProgress
        .map((AchievementProgress item) {
          int current = item.current;
          switch (item.achievement.code) {
            case 'first_task':
              current = completedTasks > 0 ? 1 : 0;
            case 'task_master_10':
              current = completedTasks;
            case 'streak_7':
              current = streak;
            case 'city_builder':
              current = buildings;
            case 'study_master':
              current = store.completedByCategory[TaskCategory.study] ?? 0;
            default:
              current = item.current;
          }

          final DateTime? unlockedAt = current >= item.target
              ? DateTime(2026, 3, 31, 20)
              : item.unlockedAt;
          return item.copyWith(current: current, unlockedAt: unlockedAt);
        })
        .toList(growable: false);

    store.user = store.user.copyWith(
      achievementsCount: store.achievementProgress
          .where((AchievementProgress item) => item.isUnlocked)
          .length,
    );
  }
}

class MockCityRepository implements CityRepository {
  const MockCityRepository(this.store);

  final MockAppStore store;

  @override
  Future<CityState> getCityState() async => store.cityState;

  @override
  Future<BuildingPurchaseResponse> purchaseBuilding(
    BuildingCreateRequest request,
  ) async {
    const int cost = 120;
    if (store.user.coins < cost) {
      throw const InsufficientCoinsException();
    }
    final int id =
        store.cityState.response.buildings.fold<int>(
          200,
          (int current, Building item) => item.id > current ? item.id : current,
        ) +
        1;
    final Building building = Building(
      id: id,
      userId: store.user.id,
      buildingType: request.buildingType,
      category: _categoryFromBuildingType(request.buildingType),
      positionX: request.positionX,
      positionY: request.positionY,
      level: 1,
      builtAt: DateTime(2026, 3, 31, 16),
      upgradedAt: null,
    );
    store.user = store.user.copyWith(
      coins: store.user.coins - cost,
      buildingsCount: store.user.buildingsCount + 1,
    );
    final List<Building> buildings = <Building>[
      ...store.cityState.response.buildings,
      building,
    ];
    final int totalLevel = buildings.fold<int>(
      0,
      (int value, Building item) => value + item.level,
    );
    store.cityState = store.cityState.copyWith(
      response: store.cityState.response.copyWith(
        buildings: buildings,
        totalBuildings: buildings.length,
        totalLevel: totalLevel,
        averageLevel: totalLevel / buildings.length,
      ),
    );
    return BuildingPurchaseResponse(
      building: building,
      cost: cost,
      balanceAfter: store.user.coins,
    );
  }

  @override
  Future<BuildingUpgradeResponse> upgradeBuilding(int buildingId) async {
    final Building current = store.cityState.response.buildings.firstWhere(
      (Building item) => item.id == buildingId,
    );
    final int cost = 50 * current.level;
    if (store.user.coins < cost) {
      throw const InsufficientCoinsException();
    }
    final List<Building> buildings = store.cityState.response.buildings
        .map((Building item) {
          if (item.id != buildingId) {
            return item;
          }
          return item.copyWith(
            level: item.level + 1,
            upgradedAt: DateTime(2026, 3, 31, 16, 30),
          );
        })
        .toList(growable: false);
    store.user = store.user.copyWith(coins: store.user.coins - cost);
    final Building upgraded = buildings.firstWhere(
      (Building item) => item.id == buildingId,
    );
    final int totalLevel = buildings.fold<int>(
      0,
      (int value, Building item) => value + item.level,
    );
    store.cityState = store.cityState.copyWith(
      response: store.cityState.response.copyWith(
        buildings: buildings,
        totalLevel: totalLevel,
        averageLevel: totalLevel / buildings.length,
      ),
    );
    return BuildingUpgradeResponse(
      building: upgraded,
      cost: cost,
      newLevel: upgraded.level,
      balanceAfter: store.user.coins,
    );
  }

  TaskCategory _categoryFromBuildingType(String value) {
    switch (value) {
      case 'университет':
        return TaskCategory.study;
      case 'офис':
        return TaskCategory.work;
      case 'спортзал':
        return TaskCategory.health;
      case 'кафе':
        return TaskCategory.personal;
      default:
        return TaskCategory.personal;
    }
  }
}

class MockAchievementRepository implements AchievementRepository {
  const MockAchievementRepository(this.store);

  final MockAppStore store;

  @override
  Future<List<AchievementProgress>> getAchievementProgress() async {
    return store.achievementProgress;
  }
}

class MockShopRepository implements ShopRepository {
  const MockShopRepository(this.store);

  final MockAppStore store;

  @override
  Future<List<ShopItem>> getItems() async => store.shopItems;

  @override
  Future<ShopItem> purchaseItem(int itemId) async {
    final int index = store.shopItems.indexWhere(
      (ShopItem item) => item.id == itemId,
    );
    final ShopItem item = store.shopItems[index];
    if (item.isOwned) {
      return item;
    }
    if (store.user.coins < item.price) {
      throw const InsufficientCoinsException();
    }
    final ShopItem updated = item.copyWith(isOwned: true);
    store.shopItems[index] = updated;
    store.user = store.user.copyWith(coins: store.user.coins - item.price);
    return updated;
  }

  @override
  Future<ShopItem> markPlaced(int itemId, {bool isPlaced = true}) async {
    final int index = store.shopItems.indexWhere(
      (ShopItem item) => item.id == itemId,
    );
    final ShopItem updated = store.shopItems[index].copyWith(
      isPlaced: isPlaced,
    );
    store.shopItems[index] = updated;
    return updated;
  }
}
