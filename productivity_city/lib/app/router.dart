import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/features/achievements/achievements_screen.dart';
import 'package:productivity_city/features/auth/login_screen.dart';
import 'package:productivity_city/features/auth/register_screen.dart';
import 'package:productivity_city/features/calendar/calendar_screen.dart';
import 'package:productivity_city/features/home/home_screen.dart';
import 'package:productivity_city/features/notifications/notification_center_screen.dart';
import 'package:productivity_city/features/onboarding/onboarding_screen.dart';
import 'package:productivity_city/features/profile/profile_screen.dart';
import 'package:productivity_city/features/settings/settings_screen.dart';
import 'package:productivity_city/features/shop/product_details_screen.dart';
import 'package:productivity_city/features/shop/shop_screen.dart';
import 'package:productivity_city/features/splash/splash_screen.dart';
import 'package:productivity_city/features/tasks/task_details_screen.dart';
import 'package:productivity_city/features/tasks/task_form_screen.dart';
import 'package:productivity_city/features/tasks/tasks_screen.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/widgets/app_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final SessionState session = ref.watch(sessionStateProvider);
  final Listenable refreshListenable = ref.watch(sessionControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final String location = state.uri.path;
      final bool isSplashRoute = location == '/';
      final bool isOnboardingRoute = location == '/onboarding';
      final bool isLoginRoute = location == '/login';
      final bool isRegisterRoute = location == '/register';
      final bool isAuthRoute = isLoginRoute || isRegisterRoute;
      final bool isPublicRoute =
          isSplashRoute || isOnboardingRoute || isAuthRoute;

      if (session.isUnknown) {
        return isSplashRoute ? null : '/';
      }

      if (session.isAuthenticated) {
        return isPublicRoute ? '/home' : null;
      }

      if (!session.hasSeenOnboarding) {
        return isOnboardingRoute ? null : '/onboarding';
      }

      if (isLoginRoute || isRegisterRoute) {
        return null;
      }

      return '/login';
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppScaffold(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/tasks',
                builder: (BuildContext context, GoRouterState state) {
                  return const TasksScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                builder: (BuildContext context, GoRouterState state) {
                  return const CalendarScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/shop',
                builder: (BuildContext context, GoRouterState state) {
                  return const ShopScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProfileScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const NotificationCenterScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/profile/achievements',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const AchievementsScreen();
        },
      ),
      GoRoute(
        path: '/tasks/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return const TaskFormScreen();
        },
      ),
      GoRoute(
        path: '/tasks/:taskId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return TaskDetailsScreen(
            taskId: state.pathParameters['taskId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/tasks/:taskId/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return TaskFormScreen(
            taskId: state.pathParameters['taskId'],
            isEditing: true,
          );
        },
      ),
      GoRoute(
        path: '/shop/:productId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          return ProductDetailsScreen(
            productId: state.pathParameters['productId'] ?? '',
          );
        },
      ),
    ],
  );
});
