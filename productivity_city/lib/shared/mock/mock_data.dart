import 'package:productivity_city/shared/models/models.dart';

const int xpPerLevel = 100;

UserProfile buildMockUserProfile() {
  return UserProfile(
    id: 1,
    email: 'aleksei@productivity.city',
    username: 'Aleksei',
    level: 3,
    xp: 340,
    coins: 275,
    streak: 5,
    createdAt: DateTime(2026, 2, 10, 9),
    lastActivityDate: DateTime(2026, 3, 30),
    xpToNextLevel: 60,
    tasksCompleted: 24,
    achievementsCount: 8,
    buildingsCount: 4,
  );
}

List<TaskWithSubtasks> buildMockTasks() {
  return <TaskWithSubtasks>[
    TaskWithSubtasks(
      id: 101,
      userId: 1,
      title: 'Подготовить презентацию',
      description: 'Для защиты курсовой работы по архитектуре ПО.',
      category: TaskCategory.study,
      priority: TaskPriority.high,
      deadline: DateTime(2026, 4, 10, 18),
      status: TaskStatus.active,
      difficulty: TaskDifficulty.medium,
      xpReward: 120,
      coinsReward: 40,
      subtasks: const <Subtask>[
        Subtask(
          id: 1001,
          taskId: 101,
          title: 'Собрать материалы',
          description: 'Найти статьи и диаграммы.',
          estimatedTime: 45,
          status: SubtaskStatus.completed,
          orderIndex: 0,
        ),
        Subtask(
          id: 1002,
          taskId: 101,
          title: 'Сделать слайды',
          estimatedTime: 90,
          status: SubtaskStatus.inProgress,
          orderIndex: 1,
        ),
        Subtask(
          id: 1003,
          taskId: 101,
          title: 'Проверить тайминг',
          estimatedTime: 20,
          status: SubtaskStatus.notStarted,
          orderIndex: 2,
        ),
      ],
      createdAt: DateTime(2026, 3, 28, 10),
      completedAt: null,
      updatedAt: DateTime(2026, 3, 30, 18),
    ),
    TaskWithSubtasks(
      id: 102,
      userId: 1,
      title: 'Сдать квартальный отчет',
      description: 'Финализировать цифры и отправить руководителю.',
      category: TaskCategory.work,
      priority: TaskPriority.high,
      deadline: DateTime(2026, 4, 2, 12),
      status: TaskStatus.inProgress,
      difficulty: TaskDifficulty.hard,
      xpReward: 180,
      coinsReward: 60,
      subtasks: const <Subtask>[
        Subtask(
          id: 1004,
          taskId: 102,
          title: 'Сверить таблицы',
          estimatedTime: 35,
          status: SubtaskStatus.completed,
          orderIndex: 0,
        ),
        Subtask(
          id: 1005,
          taskId: 102,
          title: 'Подготовить письмо',
          estimatedTime: 20,
          status: SubtaskStatus.notStarted,
          orderIndex: 1,
        ),
      ],
      createdAt: DateTime(2026, 3, 25, 9),
      completedAt: null,
      updatedAt: DateTime(2026, 3, 30, 14),
    ),
    TaskWithSubtasks(
      id: 103,
      userId: 1,
      title: 'Тренировка в спортзале',
      description: 'Сделать силовую и 20 минут кардио.',
      category: TaskCategory.health,
      priority: TaskPriority.medium,
      deadline: DateTime(2026, 4, 1, 20),
      status: TaskStatus.active,
      difficulty: TaskDifficulty.medium,
      xpReward: 90,
      coinsReward: 30,
      subtasks: const <Subtask>[],
      createdAt: DateTime(2026, 3, 31, 8),
      completedAt: null,
      updatedAt: DateTime(2026, 3, 31, 8),
    ),
    TaskWithSubtasks(
      id: 104,
      userId: 1,
      title: 'Спланировать выходные',
      description: 'Выбрать кафе и забронировать столик.',
      category: TaskCategory.personal,
      priority: TaskPriority.low,
      deadline: DateTime(2026, 4, 4, 16),
      status: TaskStatus.active,
      difficulty: TaskDifficulty.easy,
      xpReward: 60,
      coinsReward: 20,
      subtasks: const <Subtask>[],
      createdAt: DateTime(2026, 3, 29, 12),
      completedAt: null,
      updatedAt: DateTime(2026, 3, 29, 12),
    ),
    TaskWithSubtasks(
      id: 105,
      userId: 1,
      title: 'Прочитать главу книги',
      description: 'Глава по UX-исследованиям.',
      category: TaskCategory.study,
      priority: TaskPriority.medium,
      deadline: DateTime(2026, 3, 30, 21),
      status: TaskStatus.completed,
      difficulty: TaskDifficulty.easy,
      xpReward: 50,
      coinsReward: 25,
      subtasks: const <Subtask>[
        Subtask(
          id: 1006,
          taskId: 105,
          title: 'Сделать заметки',
          estimatedTime: 15,
          status: SubtaskStatus.completed,
          orderIndex: 0,
        ),
      ],
      createdAt: DateTime(2026, 3, 29, 19),
      completedAt: DateTime(2026, 3, 30, 20),
      updatedAt: DateTime(2026, 3, 30, 20),
    ),
    TaskWithSubtasks(
      id: 106,
      userId: 1,
      title: 'Отправить счета клиентам',
      description: 'Закрыть последние два инвойса за март.',
      category: TaskCategory.work,
      priority: TaskPriority.medium,
      deadline: DateTime(2026, 3, 29, 18),
      status: TaskStatus.completed,
      difficulty: TaskDifficulty.medium,
      xpReward: 110,
      coinsReward: 35,
      subtasks: const <Subtask>[
        Subtask(
          id: 1007,
          taskId: 106,
          title: 'Проверить реквизиты',
          estimatedTime: 10,
          status: SubtaskStatus.completed,
          orderIndex: 0,
        ),
      ],
      createdAt: DateTime(2026, 3, 28, 11),
      completedAt: DateTime(2026, 3, 29, 17),
      updatedAt: DateTime(2026, 3, 29, 17),
    ),
  ];
}

Map<TaskCategory, int> buildMockCompletedCategoryCounters() {
  return <TaskCategory, int>{
    TaskCategory.study: 12,
    TaskCategory.work: 7,
    TaskCategory.health: 4,
    TaskCategory.personal: 1,
  };
}

List<Character> buildMockCharacters() {
  return const <Character>[
    Character(
      id: 301,
      name: 'Mira',
      assetId: 'hero',
      position: MapPosition(x: 6, y: 2),
      message: 'Сегодня отличный день, чтобы закрыть одну большую задачу.',
    ),
    Character(
      id: 302,
      name: 'Leo',
      assetId: 'hero',
      position: MapPosition(x: 2, y: 6),
      message: 'Сначала маленький шаг, потом еще один. Так и строится город.',
    ),
  ];
}

List<MapPosition> buildMockDecorationSlots() {
  return const <MapPosition>[
    MapPosition(x: 14, y: 3),
    MapPosition(x: 21, y: 14),
    MapPosition(x: 14, y: 21),
    MapPosition(x: 13, y: 27),
  ];
}

List<Building> buildMockBuildings() {
  return <Building>[
    Building(
      id: 201,
      userId: 1,
      buildingType: 'университет',
      category: TaskCategory.study,
      positionX: 3,
      positionY: 4,
      level: 2,
      builtAt: DateTime(2026, 2, 12, 9),
      upgradedAt: DateTime(2026, 3, 22, 10),
    ),
    Building(
      id: 202,
      userId: 1,
      buildingType: 'офис',
      category: TaskCategory.work,
      positionX: 7,
      positionY: 3,
      level: 2,
      builtAt: DateTime(2026, 2, 12, 9),
      upgradedAt: DateTime(2026, 3, 20, 11),
    ),
    Building(
      id: 203,
      userId: 1,
      buildingType: 'спортзал',
      category: TaskCategory.health,
      positionX: 2,
      positionY: 8,
      level: 1,
      builtAt: DateTime(2026, 2, 12, 9),
      upgradedAt: null,
    ),
    Building(
      id: 204,
      userId: 1,
      buildingType: 'кафе',
      category: TaskCategory.personal,
      positionX: 8,
      positionY: 7,
      level: 1,
      builtAt: DateTime(2026, 2, 12, 9),
      upgradedAt: null,
    ),
  ];
}

CityState buildMockCityState() {
  final List<Building> buildings = buildMockBuildings();
  return CityState(
    response: CityResponse(
      userId: 1,
      buildings: buildings,
      totalBuildings: buildings.length,
      totalLevel: buildings.fold<int>(
        0,
        (int value, Building item) => value + item.level,
      ),
      categoryBreakdown: <String, int>{
        'study': 1,
        'work': 1,
        'health': 1,
        'personal': 1,
      },
      averageLevel:
          buildings.fold<int>(
            0,
            (int value, Building item) => value + item.level,
          ) /
          buildings.length,
    ),
    characters: buildMockCharacters(),
    freeDecorationSlots: buildMockDecorationSlots(),
  );
}

List<AchievementProgress> buildMockAchievementProgress() {
  return <AchievementProgress>[
    AchievementProgress(
      achievement: const Achievement(
        id: 401,
        code: 'first_task',
        name: 'Первые шаги',
        description: 'Создайте свою первую задачу.',
        xpReward: 10,
        coinsReward: 5,
        iconName: 'star',
      ),
      current: 1,
      target: 1,
      unlockedAt: DateTime(2026, 2, 11, 12),
    ),
    AchievementProgress(
      achievement: const Achievement(
        id: 402,
        code: 'task_master_10',
        name: 'Новичок',
        description: 'Выполните 10 задач.',
        xpReward: 50,
        coinsReward: 25,
        iconName: 'trophy_bronze',
      ),
      current: 10,
      target: 10,
      unlockedAt: DateTime(2026, 3, 12, 18),
    ),
    const AchievementProgress(
      achievement: Achievement(
        id: 403,
        code: 'streak_7',
        name: 'Неделя успеха',
        description: 'Выполняйте задачи 7 дней подряд.',
        xpReward: 70,
        coinsReward: 35,
        iconName: 'fire_strong',
      ),
      current: 5,
      target: 7,
    ),
    const AchievementProgress(
      achievement: Achievement(
        id: 404,
        code: 'city_builder',
        name: 'Градостроитель',
        description: 'Постройте 10 зданий.',
        xpReward: 100,
        coinsReward: 50,
        iconName: 'city',
      ),
      current: 4,
      target: 10,
    ),
    const AchievementProgress(
      achievement: Achievement(
        id: 405,
        code: 'study_master',
        name: 'Отличник',
        description: 'Выполните 20 задач категории учеба.',
        xpReward: 75,
        coinsReward: 40,
        iconName: 'book',
      ),
      current: 12,
      target: 20,
    ),
  ];
}

List<ShopItem> buildMockShopItems() {
  return const <ShopItem>[
    ShopItem(
      id: 501,
      name: 'Боулинг',
      description:
          'Развлекательный боулинг для верхнего квартала. После покупки сразу появляется на карте.',
      price: 140,
      type: ShopItemType.decoration,
      assetId: 'bowling',
    ),
    ShopItem(
      id: 502,
      name: 'Тир',
      description:
          'Небольшой городской тир для активной зоны. Покупка сразу размещает его на закрепленном месте.',
      price: 90,
      type: ShopItemType.decoration,
      assetId: 'shooting_range',
    ),
    ShopItem(
      id: 503,
      name: 'Фургон с пончиками',
      description:
          'Мобильная точка с перекусом для уютного квартала. После покупки сразу появляется на карте.',
      price: 110,
      type: ShopItemType.decoration,
      assetId: 'donut_van',
    ),
    ShopItem(
      id: 504,
      name: 'Кинотеатр',
      description:
          'Большой кинотеатр для нижней части города. После покупки сразу занимает свое место на карте.',
      price: 160,
      type: ShopItemType.decoration,
      assetId: 'cinema',
    ),
  ];
}
