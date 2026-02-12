import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/network/api_client.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/repositories.dart';
import 'package:productivity_city/shared/session/session_controller.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

final apiBaseUrlProvider = Provider<String>((Ref ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
});

final dataSourceProvider = Provider<DataSourceKind>((Ref ref) {
  const String rawMode = String.fromEnvironment(
    'APP_DATA_MODE',
    defaultValue: '',
  );
  if (rawMode.toLowerCase() == 'core_api') {
    return DataSourceKind.coreApi;
  }

  const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
  return useMockData ? DataSourceKind.mock : DataSourceKind.coreApi;
});

final isCoreApiModeProvider = Provider<bool>((Ref ref) {
  return ref.watch(dataSourceProvider) == DataSourceKind.coreApi;
});

final mockAppStoreProvider = Provider<MockAppStore>((Ref ref) {
  return MockAppStore.seeded();
});

final sessionStorageProvider = Provider<SessionStorage>((Ref ref) {
  return SessionStorage();
});

final apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    storage: ref.watch(sessionStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockAuthRepository(
        ref.watch(mockAppStoreProvider),
        ref.watch(sessionStorageProvider),
      );
    case DataSourceKind.coreApi:
      return ApiAuthRepository(
        client: ref.watch(apiClientProvider),
        storage: ref.watch(sessionStorageProvider),
      );
  }
});

final userRepositoryProvider = Provider<UserRepository>((Ref ref) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockUserRepository(ref.watch(mockAppStoreProvider));
    case DataSourceKind.coreApi:
      return ApiUserRepository(ref.watch(apiClientProvider));
  }
});

final taskRepositoryProvider = Provider<TaskRepository>((Ref ref) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockTaskRepository(ref.watch(mockAppStoreProvider));
    case DataSourceKind.coreApi:
      return ApiTaskRepository(ref.watch(apiClientProvider));
  }
});

final cityRepositoryProvider = Provider<CityRepository>((Ref ref) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockCityRepository(ref.watch(mockAppStoreProvider));
    case DataSourceKind.coreApi:
      return ApiCityRepository(ref.watch(apiClientProvider));
  }
});

final achievementRepositoryProvider = Provider<AchievementRepository>((
  Ref ref,
) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockAchievementRepository(ref.watch(mockAppStoreProvider));
    case DataSourceKind.coreApi:
      return CoreApiAchievementRepository();
  }
});

final shopRepositoryProvider = Provider<ShopRepository>((Ref ref) {
  switch (ref.watch(dataSourceProvider)) {
    case DataSourceKind.mock:
      return MockShopRepository(ref.watch(mockAppStoreProvider));
    case DataSourceKind.coreApi:
      return CoreApiShopRepository(ref.watch(apiClientProvider));
  }
});

final sessionControllerProvider = ChangeNotifierProvider<SessionController>((
  Ref ref,
) {
  final SessionController controller = SessionController(
    authRepository: ref.watch(authRepositoryProvider),
    storage: ref.watch(sessionStorageProvider),
    invalidateAppData: () {
      ref.invalidate(userProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(cityProvider);
      ref.invalidate(achievementsProvider);
      ref.invalidate(shopProvider);
      ref.invalidate(calendarProvider);
      ref.invalidate(localShopItemsProvider);
      ref.invalidate(localSpentCoinsProvider);
    },
  );
  unawaited(controller.restoreSession());
  return controller;
});

final sessionStateProvider = Provider<SessionState>((Ref ref) {
  return ref.watch(sessionControllerProvider).state;
});

final localShopItemsProvider = StateProvider<List<ShopItem>>((Ref ref) {
  return buildMockShopItems();
});

final localSpentCoinsProvider = StateProvider<int>((Ref ref) {
  return 0;
});

Future<T> _guardUnauthorized<T>(Ref ref, Future<T> Function() loader) async {
  try {
    return await loader();
  } on UnauthorizedException {
    await ref.read(sessionControllerProvider).handleUnauthorized();
    rethrow;
  }
}

Future<void> _ensureAuthenticatedSession(Ref ref) async {
  final SessionState session = ref.read(sessionStateProvider);
  if (session.isAuthenticated) {
    return;
  }

  if (session.isUnknown) {
    await ref.read(sessionControllerProvider).restoreSession();
    if (ref.read(sessionStateProvider).isAuthenticated) {
      return;
    }
  }

  throw StateError('Authentication required.');
}

class UserController extends AsyncNotifier<UserProfile> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  FutureOr<UserProfile> build() async {
    await _ensureAuthenticatedSession(ref);
    return _guardUnauthorized(ref, () => _repository.getCurrentUser());
  }

  Future<void> refresh() async {
    state = const AsyncLoading<UserProfile>();
    state = AsyncData<UserProfile>(
      await _guardUnauthorized(ref, () => _repository.getCurrentUser()),
    );
  }
}

class TasksController extends AsyncNotifier<List<Task>> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  FutureOr<List<Task>> build() async {
    await _ensureAuthenticatedSession(ref);
    return _guardUnauthorized(ref, () => _repository.getTasks());
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Task>>();
    state = AsyncData<List<Task>>(
      await _guardUnauthorized(ref, () => _repository.getTasks()),
    );
  }

  Future<Task> createTask(TaskCreateInput input) async {
    final DateTime requestStartedAt = DateTime.now();
    late final Task task;
    try {
      task = await _guardUnauthorized(ref, () => _repository.createTask(input));
    } catch (_) {
      final Task? recoveredTask = await _recoverCreatedTask(
        input,
        requestStartedAt: requestStartedAt,
      );
      if (recoveredTask == null) {
        rethrow;
      }
      ref.invalidateSelf();
      ref.invalidate(calendarProvider);
      return recoveredTask;
    }

    try {
      await refresh();
    } catch (_) {
      ref.invalidateSelf();
    }
    ref.invalidate(calendarProvider);
    return task;
  }

  Future<Task?> _recoverCreatedTask(
    TaskCreateInput input, {
    required DateTime requestStartedAt,
  }) async {
    try {
      final List<Task> tasks = await _guardUnauthorized(
        ref,
        () => _repository.getTasks(),
      );
      final Iterable<Task> matchingTasks = tasks.where(
        (Task task) => _matchesCreateInput(
          task,
          input,
          requestStartedAt: requestStartedAt,
        ),
      );
      if (matchingTasks.isEmpty) {
        return null;
      }

      final List<Task> sortedMatches = matchingTasks.toList(growable: false)
        ..sort((Task a, Task b) => b.id.compareTo(a.id));
      return sortedMatches.first;
    } catch (_) {
      return null;
    }
  }

  bool _matchesCreateInput(
    Task task,
    TaskCreateInput input, {
    required DateTime requestStartedAt,
  }) {
    if (task.title != input.title) {
      return false;
    }
    if (task.description != input.description) {
      return false;
    }
    if (task.category != input.category) {
      return false;
    }
    if (task.priority != input.priority) {
      return false;
    }
    if (task.difficulty != (input.difficulty ?? TaskDifficulty.medium)) {
      return false;
    }
    if (!_sameMoment(task.deadline, input.deadline)) {
      return false;
    }
    if (task.status != TaskStatus.active) {
      return false;
    }

    final DateTime recoveryWindowStart = requestStartedAt.subtract(
      const Duration(minutes: 5),
    );
    return !task.createdAt.isBefore(recoveryWindowStart);
  }

  bool _sameMoment(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.isAtSameMomentAs(right);
  }

  Future<Task> updateTask(int taskId, TaskUpdateInput input) async {
    final Task task = await _guardUnauthorized(
      ref,
      () => _repository.updateTask(taskId, input),
    );
    await refresh();
    ref.invalidate(taskDetailProvider(taskId));
    ref.invalidate(calendarProvider);
    return task;
  }

  Future<void> deleteTask(int taskId) async {
    await _guardUnauthorized(ref, () => _repository.deleteTask(taskId));
    await refresh();
    ref.invalidate(calendarProvider);
  }

  Future<TaskCompleteResult> completeTask(int taskId) async {
    final DateTime requestStartedAt = DateTime.now();
    late final TaskCompleteResult result;
    try {
      result = await _guardUnauthorized(
        ref,
        () => _repository.completeTask(taskId),
      );
    } catch (_) {
      final TaskCompleteResult? recoveredResult = await _recoverCompletedTask(
        taskId,
        requestStartedAt: requestStartedAt,
      );
      if (recoveredResult == null) {
        rethrow;
      }
      ref.invalidateSelf();
      ref.invalidate(taskDetailProvider(taskId));
      ref.invalidate(userProvider);
      ref.invalidate(cityProvider);
      ref.invalidate(achievementsProvider);
      ref.invalidate(calendarProvider);
      return recoveredResult;
    }

    try {
      await refresh();
    } catch (_) {
      ref.invalidateSelf();
    }
    ref.invalidate(taskDetailProvider(taskId));
    ref.invalidate(userProvider);
    ref.invalidate(cityProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(calendarProvider);
    return result;
  }

  Future<TaskCompleteResult?> _recoverCompletedTask(
    int taskId, {
    required DateTime requestStartedAt,
  }) async {
    try {
      final TaskWithSubtasks recoveredTask = await _guardUnauthorized(
        ref,
        () => _repository.getTask(taskId),
      );
      if (recoveredTask.status != TaskStatus.completed) {
        return null;
      }

      final DateTime recoveryWindowStart = requestStartedAt.subtract(
        const Duration(minutes: 5),
      );
      final DateTime? completedAt = recoveredTask.completedAt;
      if (completedAt != null && completedAt.isBefore(recoveryWindowStart)) {
        return null;
      }

      int? newLevel;
      int? streak;
      try {
        final UserProfile user = await _guardUnauthorized(
          ref,
          () => ref.read(userRepositoryProvider).getCurrentUser(),
        );
        newLevel = user.level;
        streak = user.streak;
      } catch (_) {
        // If follow-up profile sync fails, we still prefer the completed task
        // over surfacing a false "completion failed" message.
      }

      return TaskCompleteResult(
        task: recoveredTask.toTask(),
        xpEarned: recoveredTask.xpReward,
        coinsEarned: recoveredTask.coinsReward,
        levelUp: false,
        newLevel: newLevel,
        streak: streak,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Subtask>> splitTask(
    int taskId, {
    bool replaceExisting = false,
  }) async {
    final List<Subtask> subtasks = await _guardUnauthorized(
      ref,
      () => _repository.splitTask(taskId, replaceExisting: replaceExisting),
    );
    ref.invalidate(taskDetailProvider(taskId));
    await refresh();
    return subtasks;
  }

  Future<Subtask> updateSubtask(
    int taskId,
    int subtaskId,
    SubtaskUpdateInput input,
  ) async {
    final Subtask subtask = await _guardUnauthorized(
      ref,
      () => _repository.updateSubtask(taskId, subtaskId, input),
    );
    ref.invalidate(taskDetailProvider(taskId));
    await refresh();
    return subtask;
  }
}

class CityController extends AsyncNotifier<CityState> {
  CityRepository get _repository => ref.read(cityRepositoryProvider);

  @override
  FutureOr<CityState> build() async {
    await _ensureAuthenticatedSession(ref);
    return _guardUnauthorized(ref, () => _repository.getCityState());
  }

  Future<void> refresh() async {
    state = const AsyncLoading<CityState>();
    state = AsyncData<CityState>(
      await _guardUnauthorized(ref, () => _repository.getCityState()),
    );
  }

  Future<BuildingPurchaseResponse> purchaseBuilding(
    BuildingCreateRequest request,
  ) async {
    final BuildingPurchaseResponse result = await _guardUnauthorized(
      ref,
      () => _repository.purchaseBuilding(request),
    );
    ref.invalidate(userProvider);
    await refresh();
    return result;
  }

  Future<BuildingUpgradeResponse> upgradeBuilding(int buildingId) async {
    final BuildingUpgradeResponse result = await _guardUnauthorized(
      ref,
      () => _repository.upgradeBuilding(buildingId),
    );
    ref.invalidate(userProvider);
    await refresh();
    return result;
  }
}

class AchievementsController extends AsyncNotifier<List<AchievementProgress>> {
  @override
  FutureOr<List<AchievementProgress>> build() async {
    final UserProfile user = await ref.watch(userProvider.future);
    final List<Task> tasks = await ref.watch(tasksProvider.future);
    final CityState cityState = await ref.watch(cityProvider.future);
    return _buildAchievementProgress(
      user: user,
      tasks: tasks,
      cityState: cityState,
    );
  }
}

class ShopController extends AsyncNotifier<List<ShopItem>> {
  ShopRepository get _repository => ref.read(shopRepositoryProvider);
  bool get _isMockMode => ref.read(dataSourceProvider) == DataSourceKind.mock;

  @override
  FutureOr<List<ShopItem>> build() async {
    if (_isMockMode) {
      return ref.watch(localShopItemsProvider);
    }
    await _ensureAuthenticatedSession(ref);
    return _guardUnauthorized(ref, () => _repository.getItems());
  }

  Future<void> refresh() async {
    if (_isMockMode) {
      state = AsyncData<List<ShopItem>>(ref.read(localShopItemsProvider));
      return;
    }

    state = const AsyncLoading<List<ShopItem>>();
    state = AsyncData<List<ShopItem>>(
      await _guardUnauthorized(ref, () => _repository.getItems()),
    );
  }

  Future<ShopItem> purchaseItem(int itemId) async {
    if (!_isMockMode) {
      final ShopItem updated = await _guardUnauthorized(
        ref,
        () => _repository.purchaseItem(itemId),
      );
      final List<ShopItem> currentItems =
          state.valueOrNull ?? const <ShopItem>[];
      state = AsyncData<List<ShopItem>>(
        currentItems.isEmpty
            ? await _guardUnauthorized(ref, () => _repository.getItems())
            : <ShopItem>[
                for (final ShopItem item in currentItems)
                  item.id == itemId ? updated : item,
              ],
      );
      ref.invalidate(userProvider);
      return updated;
    }

    final List<ShopItem> items = ref.read(localShopItemsProvider);
    final int index = items.indexWhere((ShopItem item) => item.id == itemId);
    if (index < 0) {
      throw StateError('Shop item $itemId was not found.');
    }

    final ShopItem item = items[index];
    if (item.isOwned) {
      return item;
    }

    final UserProfile user = await ref.read(userProvider.future);
    final int spentCoins = ref.read(localSpentCoinsProvider);
    final int availableCoins = user.coins - spentCoins;
    if (availableCoins < item.price) {
      throw const InsufficientCoinsException();
    }

    final ShopItem updated = item.copyWith(
      isOwned: true,
      isPlaced: item.type == ShopItemType.decoration,
    );
    final List<ShopItem> updatedItems = <ShopItem>[
      for (int i = 0; i < items.length; i++) i == index ? updated : items[i],
    ];

    ref.read(localShopItemsProvider.notifier).state = updatedItems;
    ref.read(localSpentCoinsProvider.notifier).state += item.price;
    state = AsyncData<List<ShopItem>>(updatedItems);
    return updated;
  }

  Future<ShopItem> markPlaced(int itemId, {bool isPlaced = true}) async {
    if (!_isMockMode) {
      final ShopItem updated = await _guardUnauthorized(
        ref,
        () => _repository.markPlaced(itemId, isPlaced: isPlaced),
      );
      final List<ShopItem> currentItems =
          state.valueOrNull ?? const <ShopItem>[];
      state = AsyncData<List<ShopItem>>(<ShopItem>[
        for (final ShopItem item in currentItems)
          item.id == itemId ? updated : item,
      ]);
      return updated;
    }

    final List<ShopItem> items = ref.read(localShopItemsProvider);
    final int index = items.indexWhere((ShopItem item) => item.id == itemId);
    if (index < 0) {
      throw StateError('Shop item $itemId was not found.');
    }

    final ShopItem item = items[index].copyWith(isPlaced: isPlaced);
    final List<ShopItem> updatedItems = <ShopItem>[
      for (int i = 0; i < items.length; i++) i == index ? item : items[i],
    ];

    ref.read(localShopItemsProvider.notifier).state = updatedItems;
    state = AsyncData<List<ShopItem>>(updatedItems);
    return item;
  }
}

final userProvider = AsyncNotifierProvider<UserController, UserProfile>(
  UserController.new,
);

final tasksProvider = AsyncNotifierProvider<TasksController, List<Task>>(
  TasksController.new,
);

final taskDetailProvider = FutureProvider.family<TaskWithSubtasks, int>((
  Ref ref,
  int taskId,
) async {
  await _ensureAuthenticatedSession(ref);
  return _guardUnauthorized(
    ref,
    () => ref.watch(taskRepositoryProvider).getTask(taskId),
  );
});

final cityProvider = AsyncNotifierProvider<CityController, CityState>(
  CityController.new,
);

final achievementsProvider =
    AsyncNotifierProvider<AchievementsController, List<AchievementProgress>>(
      AchievementsController.new,
    );

final shopProvider = AsyncNotifierProvider<ShopController, List<ShopItem>>(
  ShopController.new,
);

final effectiveUserProvider = Provider<AsyncValue<UserProfile>>((Ref ref) {
  final AsyncValue<UserProfile> userAsync = ref.watch(userProvider);
  final bool isMockMode = ref.watch(dataSourceProvider) == DataSourceKind.mock;
  final int spentCoins = isMockMode ? ref.watch(localSpentCoinsProvider) : 0;
  final int? unlockedAchievements = ref
      .watch(achievementsProvider)
      .valueOrNull
      ?.where((AchievementProgress item) => item.isUnlocked)
      .length;

  return userAsync.whenData((UserProfile user) {
    final int adjustedCoins = user.coins - spentCoins;
    return user.copyWith(
      coins: adjustedCoins < 0 ? 0 : adjustedCoins,
      achievementsCount: unlockedAchievements ?? user.achievementsCount,
    );
  });
});

final calendarProvider = FutureProvider<Map<DateTime, List<Task>>>((
  Ref ref,
) async {
  final List<Task> tasks = await ref.watch(tasksProvider.future);
  final Map<DateTime, List<Task>> grouped = <DateTime, List<Task>>{};
  for (final Task task in tasks) {
    if (task.deadline == null) {
      continue;
    }
    final DateTime date = DateTime(
      task.deadline!.year,
      task.deadline!.month,
      task.deadline!.day,
    );
    grouped.putIfAbsent(date, () => <Task>[]).add(task);
  }
  return grouped;
});

final notificationsProvider = Provider<List<AppNotification>>((Ref ref) {
  final UserProfile? user = ref.watch(userProvider).valueOrNull;
  final List<Task> tasks =
      ref.watch(tasksProvider).valueOrNull ?? const <Task>[];

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<AppNotification> notifications = <AppNotification>[];

  final Iterable<Task> overdueTasks = tasks.where((Task task) {
    if (task.status == TaskStatus.completed || task.deadline == null) {
      return false;
    }
    final DateTime deadline = task.deadline!;
    return DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
    ).isBefore(today);
  });

  for (final Task task in overdueTasks) {
    notifications.add(
      AppNotification(
        id: 'overdue-${task.id}',
        title: 'Просроченная задача',
        body: 'Задача "${task.title}" уже вышла за дедлайн.',
        createdAt: task.deadline!,
        kind: AppNotificationKind.warning,
        taskId: task.id,
        isUnread: true,
      ),
    );
  }

  final Iterable<Task> todayTasks = tasks.where((Task task) {
    if (task.status == TaskStatus.completed || task.deadline == null) {
      return false;
    }
    final DateTime deadline = task.deadline!;
    final DateTime normalized = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
    );
    return normalized == today;
  });

  for (final Task task in todayTasks) {
    notifications.add(
      AppNotification(
        id: 'today-${task.id}',
        title: 'Дедлайн сегодня',
        body: 'Не забудь закрыть "${task.title}" до конца дня.',
        createdAt: task.deadline!,
        kind: AppNotificationKind.reminder,
        taskId: task.id,
        isUnread: true,
      ),
    );
  }

  final Iterable<Task> upcomingTasks = tasks.where((Task task) {
    if (task.status == TaskStatus.completed || task.deadline == null) {
      return false;
    }
    final DateTime deadline = task.deadline!;
    final DateTime normalized = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
    );
    final int days = normalized.difference(today).inDays;
    return days > 0 && days <= 3;
  });

  for (final Task task in upcomingTasks.take(3)) {
    notifications.add(
      AppNotification(
        id: 'soon-${task.id}',
        title: 'Ближайший дедлайн',
        body: 'Скоро наступит срок по задаче "${task.title}".',
        createdAt: task.deadline!,
        kind: AppNotificationKind.info,
        taskId: task.id,
      ),
    );
  }

  final List<Task> recentCompleted =
      tasks
          .where(
            (Task task) =>
                task.status == TaskStatus.completed && task.completedAt != null,
          )
          .toList()
        ..sort((Task a, Task b) => b.completedAt!.compareTo(a.completedAt!));

  for (final Task task in recentCompleted.take(2)) {
    notifications.add(
      AppNotification(
        id: 'done-${task.id}',
        title: 'Награда начислена',
        body:
            'За "${task.title}" получено ${task.xpReward} XP и ${task.coinsReward} монет.',
        createdAt: task.completedAt!,
        kind: AppNotificationKind.reward,
        taskId: task.id,
      ),
    );
  }

  if (user != null) {
    notifications.add(
      AppNotification(
        id: 'streak-${user.streak}',
        title: 'Серия продолжается',
        body:
            'Текущая серия: ${user.streak} дней. Город растет вместе с тобой.',
        createdAt: user.lastActivityDate ?? user.createdAt,
        kind: AppNotificationKind.info,
      ),
    );
  }

  notifications.sort((AppNotification a, AppNotification b) {
    if (a.isUnread != b.isUnread) {
      return a.isUnread ? -1 : 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return notifications;
});

final unreadNotificationsCountProvider = Provider<int>((Ref ref) {
  return ref
      .watch(notificationsProvider)
      .where((AppNotification item) => item.isUnread)
      .length;
});

List<AchievementProgress> _buildAchievementProgress({
  required UserProfile user,
  required List<Task> tasks,
  required CityState cityState,
}) {
  final List<Task> completedTasks = tasks
      .where((Task task) => task.status == TaskStatus.completed)
      .toList(growable: false);
  final DateTime achievementDate =
      user.lastActivityDate ??
      completedTasks
          .where((Task task) => task.completedAt != null)
          .map((Task task) => task.completedAt!)
          .fold<DateTime>(user.createdAt, (DateTime latest, DateTime current) {
            return current.isAfter(latest) ? current : latest;
          });

  int completedInCategory(TaskCategory category) {
    return completedTasks
        .where((Task task) => task.category == category)
        .length;
  }

  AchievementProgress achievement({
    required int id,
    required String code,
    required String name,
    required String description,
    required int xpReward,
    required int coinsReward,
    required int current,
    required int target,
    String? iconName,
  }) {
    final bool isUnlocked = current >= target;
    return AchievementProgress(
      achievement: Achievement(
        id: id,
        code: code,
        name: name,
        description: description,
        xpReward: xpReward,
        coinsReward: coinsReward,
        iconName: iconName,
      ),
      current: current,
      target: target,
      unlockedAt: isUnlocked ? achievementDate : null,
    );
  }

  return <AchievementProgress>[
    achievement(
      id: 401,
      code: 'first_task',
      name: 'Первые шаги',
      description: 'Создай свою первую задачу.',
      xpReward: 10,
      coinsReward: 5,
      current: tasks.isEmpty ? 0 : 1,
      target: 1,
      iconName: 'star',
    ),
    achievement(
      id: 402,
      code: 'task_master_10',
      name: 'Новичок',
      description: 'Выполни 10 задач.',
      xpReward: 50,
      coinsReward: 25,
      current: completedTasks.length,
      target: 10,
      iconName: 'trophy_bronze',
    ),
    achievement(
      id: 403,
      code: 'streak_7',
      name: 'Неделя успеха',
      description: 'Держи серию активности 7 дней подряд.',
      xpReward: 70,
      coinsReward: 35,
      current: user.streak,
      target: 7,
      iconName: 'fire_strong',
    ),
    achievement(
      id: 404,
      code: 'city_builder',
      name: 'Градостроитель',
      description: 'Открой все базовые здания города.',
      xpReward: 100,
      coinsReward: 50,
      current: cityState.response.totalBuildings,
      target: 4,
      iconName: 'city',
    ),
    achievement(
      id: 405,
      code: 'study_master',
      name: 'Отличник',
      description: 'Выполни 10 задач в категории "Учеба".',
      xpReward: 75,
      coinsReward: 40,
      current: completedInCategory(TaskCategory.study),
      target: 10,
      iconName: 'book',
    ),
    achievement(
      id: 406,
      code: 'work_master',
      name: 'Профи',
      description: 'Выполни 7 задач в категории "Работа".',
      xpReward: 75,
      coinsReward: 40,
      current: completedInCategory(TaskCategory.work),
      target: 7,
      iconName: 'briefcase',
    ),
    achievement(
      id: 407,
      code: 'health_rhythm',
      name: 'Ритм здоровья',
      description: 'Выполни 4 задачи в категории "Здоровье".',
      xpReward: 60,
      coinsReward: 30,
      current: completedInCategory(TaskCategory.health),
      target: 4,
      iconName: 'heart',
    ),
    achievement(
      id: 408,
      code: 'personal_balance',
      name: 'Личный баланс',
      description: 'Выполни 5 задач в категории "Личное".',
      xpReward: 60,
      coinsReward: 30,
      current: completedInCategory(TaskCategory.personal),
      target: 5,
      iconName: 'sparkles',
    ),
  ];
}
