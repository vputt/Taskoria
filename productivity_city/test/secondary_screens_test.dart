import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/app/app.dart';
import 'package:productivity_city/features/achievements/achievements_screen.dart';
import 'package:productivity_city/features/notifications/notification_center_screen.dart';
import 'package:productivity_city/features/onboarding/onboarding_screen.dart';
import 'package:productivity_city/features/settings/settings_screen.dart';
import 'package:productivity_city/features/shop/product_details_screen.dart';
import 'package:productivity_city/features/tasks/task_details_screen.dart';
import 'package:productivity_city/features/tasks/widgets/subtask_tile.dart';
import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class FakeSessionStorage extends SessionStorage {
  FakeSessionStorage({this.token = 'mock-session-token', this.seen = true});

  String? token;
  bool seen;

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
  Future<bool> readHasSeenOnboarding() async => seen;

  @override
  Future<void> writeHasSeenOnboarding(bool value) async {
    seen = value;
  }
}

Widget _screen(
  Widget child, {
  FakeSessionStorage? storage,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      sessionStorageProvider.overrideWithValue(storage ?? FakeSessionStorage()),
      ...overrides,
    ],
    child: MaterialApp(home: child),
  );
}

Widget _appWithStorage(FakeSessionStorage storage) {
  return ProviderScope(
    overrides: <Override>[sessionStorageProvider.overrideWithValue(storage)],
    child: const ProductivityCityApp(),
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
}) async {
  for (int i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('onboarding skip marks onboarding as seen', (
    WidgetTester tester,
  ) async {
    final FakeSessionStorage storage = FakeSessionStorage(
      token: null,
      seen: false,
    );

    await tester.pumpWidget(_appWithStorage(storage));
    await _pumpUntilFound(tester, find.byType(OnboardingScreen));

    await tester.tap(find.byType(TextButton).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(storage.seen, isTrue);
  });

  testWidgets('task details renders subtasks and supports task actions', (
    WidgetTester tester,
  ) async {
    final TaskWithSubtasks task = buildMockTasks()[1];

    await tester.pumpWidget(_screen(TaskDetailsScreen(taskId: '${task.id}')));
    await _pumpUntilFound(tester, find.text(task.title));

    expect(find.byType(SubtaskTile), findsNWidgets(task.subtasks.length));

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump(const Duration(milliseconds: 250));
    await _pumpUntilFound(tester, find.text(task.title));

    expect(find.text(task.title), findsOneWidget);
  });

  testWidgets('task details can split an active task without subtasks', (
    WidgetTester tester,
  ) async {
    final TaskWithSubtasks task = buildMockTasks()[2];

    await tester.pumpWidget(_screen(TaskDetailsScreen(taskId: '${task.id}')));
    await _pumpUntilFound(tester, find.text(task.title));

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(task.title), findsOneWidget);
  });

  testWidgets('product details purchases an affordable shop item', (
    WidgetTester tester,
  ) async {
    final ShopItem item = buildMockShopItems().first;

    await tester.pumpWidget(
      _screen(ProductDetailsScreen(productId: '${item.id}')),
    );
    await _pumpUntilFound(tester, find.text(item.name));

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpUntilFound(tester, find.text(item.name));

    expect(find.text(item.name), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('product details handles malformed product id', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _screen(const ProductDetailsScreen(productId: 'bad')),
    );
    await tester.pump();

    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('achievements screen renders calculated progress cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_screen(const AchievementsScreen()));
    await _pumpUntilFound(tester, find.byType(LinearProgressIndicator));

    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
  });

  testWidgets('settings toggles preferences and logs out', (
    WidgetTester tester,
  ) async {
    final FakeSessionStorage storage = FakeSessionStorage();

    await tester.pumpWidget(_screen(const SettingsScreen(), storage: storage));
    await tester.pump();

    expect(find.byType(Switch), findsNWidgets(3));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    await tester.ensureVisible(find.byIcon(Icons.logout_rounded));
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pump(const Duration(milliseconds: 250));

    expect(storage.token, isNull);
  });

  testWidgets('notification center renders unread and earlier groups', (
    WidgetTester tester,
  ) async {
    final List<AppNotification> notifications = <AppNotification>[
      AppNotification(
        id: 'warning',
        title: 'Deadline warning',
        body: 'Task is overdue',
        createdAt: DateTime(2026, 5, 20, 9),
        kind: AppNotificationKind.warning,
        taskId: 101,
        isUnread: true,
      ),
      AppNotification(
        id: 'reward',
        title: 'Reward received',
        body: 'Coins were added',
        createdAt: DateTime(2026, 5, 19, 10),
        kind: AppNotificationKind.reward,
      ),
      AppNotification(
        id: 'reminder',
        title: 'Today reminder',
        body: 'Finish the task today',
        createdAt: DateTime(2026, 5, 20, 8),
        kind: AppNotificationKind.reminder,
        isUnread: true,
      ),
      AppNotification(
        id: 'info',
        title: 'City update',
        body: 'Your streak is alive',
        createdAt: DateTime(2026, 5, 18, 8),
        kind: AppNotificationKind.info,
      ),
    ];

    await tester.pumpWidget(
      _screen(
        const NotificationCenterScreen(),
        overrides: <Override>[
          notificationsProvider.overrideWithValue(notifications),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Deadline warning'), findsOneWidget);
    expect(find.text('Reward received'), findsOneWidget);
    expect(find.text('Today reminder'), findsOneWidget);
    expect(find.text('City update'), findsOneWidget);
  });
}
