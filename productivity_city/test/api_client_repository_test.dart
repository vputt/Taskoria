import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/network/api_client.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/api_repositories.dart';
import 'package:productivity_city/shared/providers/repository_contracts.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class FakeSessionStorage extends SessionStorage {
  FakeSessionStorage({this.token = 'initial-token'});

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

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  unawaited(
    Future<void>(() async {
      await for (final HttpRequest request in server) {
        await handler(request);
      }
    }),
  );
  return server;
}

Future<String> _readBody(HttpRequest request) {
  return utf8.decoder.bind(request).join();
}

Future<void> _json(
  HttpRequest request,
  Object? data, {
  int statusCode = HttpStatus.ok,
}) async {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(data));
  await request.response.close();
}

Future<void> _notFound(HttpRequest request) {
  return _json(request, <String, Object>{
    'detail': 'Not found',
  }, statusCode: HttpStatus.notFound);
}

String _baseUrl(HttpServer server) {
  return 'http://${server.address.host}:${server.port}';
}

void main() {
  test('ApiClient sends auth header and maps server errors', () async {
    final FakeSessionStorage storage = FakeSessionStorage();
    String? authHeader;

    final HttpServer server = await _startServer((HttpRequest request) async {
      switch (request.uri.path) {
        case '/api/ping':
          authHeader = request.headers.value(HttpHeaders.authorizationHeader);
          return _json(request, <String, Object>{'ok': true});
        case '/api/form':
          final String body = await _readBody(request);
          return _json(request, <String, Object>{'body': body});
        case '/api/validation':
          return _json(request, <String, Object>{
            'detail': <Map<String, Object>>[
              <String, Object>{
                'loc': <String>['body', 'email'],
                'msg': 'value is not a valid email',
              },
            ],
          }, statusCode: HttpStatus.unprocessableEntity);
        case '/api/unauthorized':
          return _json(request, <String, Object>{
            'detail': 'Token expired',
          }, statusCode: HttpStatus.unauthorized);
      }
      return _notFound(request);
    });
    addTearDown(() => server.close(force: true));

    final ApiClient client = ApiClient(
      baseUrl: _baseUrl(server),
      storage: storage,
    );

    expect(await client.get('/ping'), <String, Object>{'ok': true});
    expect(authHeader, 'Bearer initial-token');

    final Map<String, dynamic> formResponse = Map<String, dynamic>.from(
      await client.postForm('/form', data: <String, dynamic>{'name': 'Task'}),
    );
    expect(formResponse['body'], contains('name=Task'));

    await expectLater(
      client.get('/validation'),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.message,
          'message',
          contains('email'),
        ),
      ),
    );

    await expectLater(
      client.get('/unauthorized'),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(storage.token, isNull);
  });

  test(
    'API repositories parse success responses and map domain errors',
    () async {
      final FakeSessionStorage storage = FakeSessionStorage();
      final UserProfile user = buildMockUserProfile();
      final TaskWithSubtasks task = buildMockTasks().first;
      final Building building = buildMockBuildings().first;
      final ShopItem shopItem = buildMockShopItems().first;

      final HttpServer server = await _startServer((HttpRequest request) async {
        final String path = request.uri.path;
        if (path == '/api/auth/register' && request.method == 'POST') {
          await _readBody(request);
          return _json(request, <String, Object>{'created': true});
        }
        if (path == '/api/auth/login' && request.method == 'POST') {
          return _json(request, <String, Object>{
            'access_token': 'server-token',
          });
        }
        if (path == '/api/users/me' && request.method == 'GET') {
          return _json(request, user.toJson());
        }
        if (path == '/api/tasks' && request.method == 'GET') {
          return _json(
            request,
            buildMockTasks()
                .map((TaskWithSubtasks item) => item.toJson())
                .toList(),
          );
        }
        if (path == '/api/tasks' && request.method == 'POST') {
          return _json(request, task.toJson());
        }
        if (path == '/api/tasks/${task.id}' && request.method == 'GET') {
          return _json(request, task.toJson());
        }
        if (path == '/api/tasks/${task.id}' && request.method == 'PATCH') {
          return _json(
            request,
            task.copyWith(status: TaskStatus.inProgress).toJson(),
          );
        }
        if (path == '/api/tasks/${task.id}' && request.method == 'DELETE') {
          return _json(request, <String, Object>{'deleted': true});
        }
        if (path == '/api/tasks/${task.id}/complete' &&
            request.method == 'POST') {
          return _json(
            request,
            TaskCompleteResult(
              task: task.copyWith(status: TaskStatus.completed).toTask(),
              xpEarned: task.xpReward,
              coinsEarned: task.coinsReward,
              levelUp: true,
              newLevel: user.level + 1,
              streak: user.streak + 1,
            ).toJson(),
          );
        }
        if (path == '/api/tasks/${task.id}/split' && request.method == 'POST') {
          if (request.uri.queryParameters['replace_existing'] == 'true') {
            return _json(
              request,
              task.subtasks.map((Subtask subtask) => subtask.toJson()).toList(),
            );
          }
          return _json(request, <String, Object>{
            'detail': 'Subtasks already exist',
          }, statusCode: HttpStatus.conflict);
        }
        if (path == '/api/tasks/${task.id}/subtasks/${task.subtasks.last.id}' &&
            request.method == 'PATCH') {
          return _json(
            request,
            task.subtasks.last
                .copyWith(status: SubtaskStatus.completed)
                .toJson(),
          );
        }
        if (path == '/api/city' && request.method == 'GET') {
          return _json(request, buildMockCityState().response.toJson());
        }
        if (path == '/api/city/buildings' && request.method == 'POST') {
          return _json(request, <String, Object>{
            'building': building.toJson(),
            'cost': 100,
            'balance_after': 175,
          });
        }
        if (path == '/api/city/buildings/${building.id}/upgrade' &&
            request.method == 'PATCH') {
          return _json(request, <String, Object>{
            'building': building.copyWith(level: 3).toJson(),
            'cost': 80,
            'new_level': 3,
            'balance_after': 95,
          });
        }
        if (path == '/api/city/buildings/999/upgrade' &&
            request.method == 'PATCH') {
          return _json(request, <String, Object>{
            'detail': 'Insufficient funds',
          }, statusCode: HttpStatus.badRequest);
        }
        if (path == '/api/shop' && request.method == 'GET') {
          return _json(
            request,
            buildMockShopItems().map((ShopItem item) => item.toJson()).toList(),
          );
        }
        if (path == '/api/shop/items/${shopItem.id}/purchase' &&
            request.method == 'POST') {
          return _json(request, shopItem.copyWith(isOwned: true).toJson());
        }
        if (path == '/api/shop/items/999/purchase' &&
            request.method == 'POST') {
          return _json(request, <String, Object>{
            'detail': 'Insufficient funds',
          }, statusCode: HttpStatus.badRequest);
        }
        if (path == '/api/shop/items/${shopItem.id}/placement' &&
            request.method == 'PATCH') {
          return _json(
            request,
            shopItem.copyWith(isOwned: true, isPlaced: true).toJson(),
          );
        }
        return _notFound(request);
      });
      addTearDown(() => server.close(force: true));

      final ApiClient client = ApiClient(
        baseUrl: _baseUrl(server),
        storage: storage,
      );
      final AuthRepository authRepository = ApiAuthRepository(
        client: client,
        storage: storage,
      );
      final ApiTaskRepository taskRepository = ApiTaskRepository(client);
      final ApiCityRepository cityRepository = ApiCityRepository(client);
      final CoreApiShopRepository shopRepository = CoreApiShopRepository(
        client,
      );

      await authRepository.register(
        email: user.email,
        username: user.username,
        password: 'password123',
      );
      final AuthSession session = await authRepository.login(
        email: user.email,
        password: 'password123',
      );
      expect(session.token, 'server-token');
      expect(storage.token, 'server-token');

      expect(await authRepository.restoreSession(), isA<AuthSession>());
      expect(
        (await ApiUserRepository(client).getCurrentUser()).username,
        user.username,
      );

      final List<Task> studyTasks = await taskRepository.getTasks(
        category: TaskCategory.study,
      );
      expect(
        studyTasks.every((Task item) => item.category == TaskCategory.study),
        isTrue,
      );

      expect((await taskRepository.getTask(task.id)).subtasks, isNotEmpty);
      expect(
        (await taskRepository.createTask(
          TaskCreateInput(
            title: task.title,
            category: task.category,
            priority: task.priority,
          ),
        )).id,
        task.id,
      );
      expect(
        (await taskRepository.updateTask(
          task.id,
          const TaskUpdateInput(status: TaskStatus.inProgress),
        )).status,
        TaskStatus.inProgress,
      );
      await taskRepository.deleteTask(task.id);
      expect((await taskRepository.completeTask(task.id)).levelUp, isTrue);

      await expectLater(
        taskRepository.splitTask(task.id),
        throwsA(isA<SubtasksAlreadyExistException>()),
      );
      expect(
        await taskRepository.splitTask(task.id, replaceExisting: true),
        isNotEmpty,
      );
      expect(
        (await taskRepository.updateSubtask(
          task.id,
          task.subtasks.last.id,
          const SubtaskUpdateInput(status: SubtaskStatus.completed),
        )).status,
        SubtaskStatus.completed,
      );

      expect((await cityRepository.getCityState()).buildings, isNotEmpty);
      expect(
        (await cityRepository.purchaseBuilding(
          const BuildingCreateRequest(
            buildingType: 'office',
            positionX: 1,
            positionY: 1,
          ),
        )).balanceAfter,
        175,
      );
      expect((await cityRepository.upgradeBuilding(building.id)).newLevel, 3);
      await expectLater(
        cityRepository.upgradeBuilding(999),
        throwsA(isA<InsufficientCoinsException>()),
      );

      expect(
        () => CoreApiAchievementRepository().getAchievementProgress(),
        throwsA(isA<FeatureUnavailableException>()),
      );
      expect(await shopRepository.getItems(), isNotEmpty);
      expect((await shopRepository.purchaseItem(shopItem.id)).isOwned, isTrue);
      await expectLater(
        shopRepository.purchaseItem(999),
        throwsA(isA<InsufficientCoinsException>()),
      );
      expect(
        (await shopRepository.markPlaced(shopItem.id, isPlaced: true)).isPlaced,
        isTrue,
      );
    },
  );
}
