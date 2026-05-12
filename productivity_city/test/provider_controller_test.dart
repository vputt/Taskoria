import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/mock_repositories.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/providers/repository_contracts.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class FakeSessionStorage extends SessionStorage {
  FakeSessionStorage({this.token = 'mock-session-token'});

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clearToken() async {
    token = null;
  }

  @override
  Future<bool> readHasSeenOnboarding() async => true;

  @override
  Future<void> writeHasSeenOnboarding(bool value) async {}
}

ProviderContainer _container() {
  final MockAppStore store = MockAppStore.seeded();
  store.shopItems = store.shopItems.toList();
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sessionStorageProvider.overrideWithValue(FakeSessionStorage()),
      mockAppStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'task repository creates, splits, updates and completes a task',
    () async {
      final ProviderContainer container = _container();
      final TaskRepository repository = container.read(taskRepositoryProvider);

      final List<Task> initialTasks = await repository.getTasks();
      expect(initialTasks, isNotEmpty);

      final Task created = await repository.createTask(
        const TaskCreateInput(
          title: 'Controller coverage task',
          category: TaskCategory.study,
          priority: TaskPriority.high,
          difficulty: TaskDifficulty.hard,
        ),
      );

      expect(created.title, 'Controller coverage task');
      expect(created.xpReward, 180);

      final List<Subtask> subtasks = await repository.splitTask(created.id);
      expect(subtasks, hasLength(3));

      final Subtask updatedSubtask = await repository.updateSubtask(
        created.id,
        subtasks.first.id,
        const SubtaskUpdateInput(status: SubtaskStatus.completed),
      );
      expect(updatedSubtask.status, SubtaskStatus.completed);

      final Task updated = await repository.updateTask(
        created.id,
        const TaskUpdateInput(status: TaskStatus.inProgress),
      );
      expect(updated.status, TaskStatus.inProgress);

      final TaskCompleteResult result = await repository.completeTask(
        created.id,
      );
      expect(result.task.status, TaskStatus.completed);
      expect(result.xpEarned, created.xpReward);

      final UserProfile user = await container
          .read(userRepositoryProvider)
          .getCurrentUser();
      expect(user.tasksCompleted, greaterThan(24));
    },
  );

  test('city and shop repositories update app state in mock mode', () async {
    final ProviderContainer container = _container();
    final CityRepository cityRepository = container.read(
      cityRepositoryProvider,
    );
    final ShopRepository shopRepository = container.read(
      shopRepositoryProvider,
    );

    final CityState cityBefore = await cityRepository.getCityState();
    final int buildingCount = cityBefore.response.totalBuildings;

    final BuildingPurchaseResponse purchase = await cityRepository
        .purchaseBuilding(
          const BuildingCreateRequest(
            buildingType: 'офис',
            positionX: 11,
            positionY: 11,
          ),
        );

    expect(purchase.building.positionX, 11);
    final CityState cityAfter = await cityRepository.getCityState();
    expect(cityAfter.response.totalBuildings, buildingCount + 1);

    final List<ShopItem> items = await shopRepository.getItems();
    final ShopItem notOwned = items.firstWhere(
      (ShopItem item) => !item.isOwned,
    );

    final ShopItem purchased = await shopRepository.purchaseItem(notOwned.id);
    expect(purchased.isOwned, isTrue);

    final UserProfile user = await container
        .read(userRepositoryProvider)
        .getCurrentUser();
    expect(user.coins, lessThan(275));
  });

  test('notifications and calendar providers derive data from tasks', () async {
    final ProviderContainer container = _container();

    final Map<DateTime, List<Task>> calendar = await container.read(
      calendarProvider.future,
    );
    expect(calendar.values.expand((List<Task> tasks) => tasks), isNotEmpty);

    await container.read(userProvider.future);
    await container.read(tasksProvider.future);
    final List<AppNotification> notifications = container.read(
      notificationsProvider,
    );

    expect(notifications, isNotEmpty);
    expect(container.read(unreadNotificationsCountProvider), greaterThan(0));
  });

  test('shop controller rejects missing item ids', () async {
    final ProviderContainer container = _container();

    final ShopRepository repository = container.read(shopRepositoryProvider);

    await expectLater(
      repository.purchaseItem(999999),
      throwsA(isA<RangeError>()),
    );
    await expectLater(
      repository.markPlaced(999999),
      throwsA(isA<RangeError>()),
    );
  });

  test('unauthenticated provider access fails before data loading', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sessionStorageProvider.overrideWithValue(
          FakeSessionStorage(token: null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(tasksProvider.future),
      throwsA(isA<StateError>()),
    );
  });
}
