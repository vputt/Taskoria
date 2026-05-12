import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/app/app.dart';
import 'package:productivity_city/features/auth/login_screen.dart';
import 'package:productivity_city/features/auth/register_screen.dart';
import 'package:productivity_city/features/calendar/calendar_screen.dart';
import 'package:productivity_city/features/home/home_screen.dart';
import 'package:productivity_city/features/profile/profile_screen.dart';
import 'package:productivity_city/features/shop/shop_screen.dart';
import 'package:productivity_city/features/tasks/task_form_screen.dart';
import 'package:productivity_city/features/tasks/tasks_screen.dart';
import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/session/session_storage.dart';
import 'package:productivity_city/shared/widgets/app_bottom_nav.dart';

class FakeSessionStorage extends SessionStorage {
  FakeSessionStorage({this.token, this.hasSeenOnboarding = true});

  String? token;
  bool hasSeenOnboarding;

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
  Future<bool> readHasSeenOnboarding() async => hasSeenOnboarding;

  @override
  Future<void> writeHasSeenOnboarding(bool value) async {
    hasSeenOnboarding = value;
  }
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
  int maxPumps = 30,
}) async {
  for (int i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsWidgets);
}

Finder _bottomNavButton(int index) {
  return find
      .descendant(of: find.byType(AppBottomNav), matching: find.byType(InkWell))
      .at(index);
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

  testWidgets('unauthenticated user who saw onboarding is routed to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _appWithStorage(FakeSessionStorage(hasSeenOnboarding: true)),
    );

    await _pumpUntilFound(tester, find.byType(LoginScreen));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('login form authenticates and opens the city screen', (
    WidgetTester tester,
  ) async {
    final FakeSessionStorage storage = FakeSessionStorage(
      hasSeenOnboarding: true,
    );
    await tester.pumpWidget(_appWithStorage(storage));
    await _pumpUntilFound(tester, find.byType(LoginScreen));

    await tester.enterText(find.byType(TextField).at(0), 'student@test.dev');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.byType(FilledButton));

    await _pumpUntilFound(tester, find.byType(HomeScreen));

    expect(storage.token, 'mock-session-token');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('register link opens register screen', (
    WidgetTester tester,
  ) async {
    final FakeSessionStorage storage = FakeSessionStorage(
      hasSeenOnboarding: true,
    );
    await tester.pumpWidget(_appWithStorage(storage));
    await _pumpUntilFound(tester, find.byType(LoginScreen));

    await tester.ensureVisible(find.byType(TextButton).last);
    await tester.pump();
    await tester.tap(find.byType(TextButton).last);
    await _pumpUntilFound(tester, find.byType(RegisterScreen));

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RegisterScreen),
        matching: find.byType(TextField),
      ),
      findsNWidgets(3),
    );
    expect(storage.token, isNull);
  });

  testWidgets('bottom navigation opens main authenticated sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _appWithStorage(
        FakeSessionStorage(
          token: 'mock-session-token',
          hasSeenOnboarding: true,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.byType(HomeScreen));

    await tester.tap(_bottomNavButton(1));
    await _pumpUntilFound(tester, find.byType(TasksScreen));
    expect(find.text(buildMockTasks().first.title), findsOneWidget);

    await tester.tap(_bottomNavButton(2));
    await _pumpUntilFound(tester, find.byType(CalendarScreen));
    expect(find.byType(CalendarScreen), findsOneWidget);

    await tester.tap(_bottomNavButton(3));
    await _pumpUntilFound(tester, find.byType(ShopScreen));
    expect(find.text(buildMockShopItems().first.name), findsOneWidget);

    await tester.tap(_bottomNavButton(4));
    await _pumpUntilFound(tester, find.byType(ProfileScreen));
    expect(find.text(buildMockUserProfile().username), findsOneWidget);
  });

  testWidgets('floating action button opens task creation form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _appWithStorage(
        FakeSessionStorage(
          token: 'mock-session-token',
          hasSeenOnboarding: true,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.byType(HomeScreen));

    await tester.tap(find.byKey(const ValueKey<String>('create-task-fab')));
    await _pumpUntilFound(tester, find.byType(TaskFormScreen));

    expect(find.byType(TaskFormScreen), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('tasks search filters visible task cards', (
    WidgetTester tester,
  ) async {
    final String visibleTitle = buildMockTasks()[2].title;
    final String hiddenTitle = buildMockTasks()[0].title;

    await tester.pumpWidget(
      _appWithStorage(
        FakeSessionStorage(
          token: 'mock-session-token',
          hasSeenOnboarding: true,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.byType(HomeScreen));

    await tester.tap(_bottomNavButton(1));
    await _pumpUntilFound(tester, find.byType(TasksScreen));

    await tester.enterText(find.byType(TextField).first, visibleTitle);
    await tester.pump();

    expect(find.text(visibleTitle), findsWidgets);
    expect(find.text(hiddenTitle), findsNothing);
  });
}
