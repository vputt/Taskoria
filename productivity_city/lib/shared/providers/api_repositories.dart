import 'package:productivity_city/shared/mock/mock_data.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/network/api_client.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/repository_contracts.dart';
import 'package:productivity_city/shared/session/session_state.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient client,
    required SessionStorage storage,
  }) : _client = client,
       _storage = storage;

  final ApiClient _client;
  final SessionStorage _storage;

  @override
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    await _client.post(
      '/auth/register',
      data: <String, dynamic>{
        'email': email,
        'username': username,
        'password': password,
      },
    );
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = _asMap(
      await _client.postForm(
        '/auth/login',
        data: <String, dynamic>{'username': email, 'password': password},
      ),
    );
    final String token = data['access_token'] as String;
    await _storage.writeToken(token);
    try {
      final Map<String, dynamic> userData = _asMap(
        await _client.get('/users/me'),
      );
      return AuthSession(token: token, user: UserProfile.fromJson(userData));
    } catch (_) {
      await _storage.clearToken();
      rethrow;
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final String? token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> userData = _asMap(
        await _client.get('/users/me'),
      );
      return AuthSession(token: token, user: UserProfile.fromJson(userData));
    } on UnauthorizedException {
      await _storage.clearToken();
      return null;
    }
  }

  @override
  Future<void> logout() => _storage.clearToken();
}

class ApiUserRepository implements UserRepository {
  ApiUserRepository(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile> getCurrentUser() async {
    final Map<String, dynamic> data = _asMap(await _client.get('/users/me'));
    return UserProfile.fromJson(data);
  }
}

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskCategory? category,
  }) async {
    final List<dynamic> data = _asList(await _client.get('/tasks'));
    List<Task> tasks = data
        .map((dynamic item) => Task.fromJson(_asMap(item)))
        .toList(growable: false);

    if (status != null) {
      tasks = tasks
          .where((Task item) => item.status == status)
          .toList(growable: false);
    }
    if (category != null) {
      tasks = tasks
          .where((Task item) => item.category == category)
          .toList(growable: false);
    }
    return tasks;
  }

  @override
  Future<TaskWithSubtasks> getTask(int taskId) async {
    final Map<String, dynamic> data = _asMap(
      await _client.get('/tasks/$taskId'),
    );
    return TaskWithSubtasks.fromJson(data);
  }

  @override
  Future<Task> createTask(TaskCreateInput input) async {
    final Map<String, dynamic> data = _asMap(
      await _client.post('/tasks', data: input.toJson()),
    );
    return Task.fromJson(data);
  }

  @override
  Future<Task> updateTask(int taskId, TaskUpdateInput input) async {
    final Map<String, dynamic> data = _asMap(
      await _client.patch('/tasks/$taskId', data: input.toJson()),
    );
    return Task.fromJson(data);
  }

  @override
  Future<void> deleteTask(int taskId) async {
    await _client.delete('/tasks/$taskId');
  }

  @override
  Future<TaskCompleteResult> completeTask(int taskId) async {
    final Map<String, dynamic> data = _asMap(
      await _client.post('/tasks/$taskId/complete'),
    );
    return TaskCompleteResult.fromJson(data);
  }

  @override
  Future<List<Subtask>> splitTask(
    int taskId, {
    bool replaceExisting = false,
  }) async {
    try {
      final List<dynamic> data = _asList(
        await _client.post(
          '/tasks/$taskId/split',
          queryParameters: <String, dynamic>{
            'replace_existing': replaceExisting,
          },
        ),
      );
      return data
          .map((dynamic item) => Subtask.fromJson(_asMap(item)))
          .toList(growable: false);
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        throw const SubtasksAlreadyExistException();
      }
      rethrow;
    }
  }

  @override
  Future<Subtask> updateSubtask(
    int taskId,
    int subtaskId,
    SubtaskUpdateInput input,
  ) async {
    final Map<String, dynamic> data = _asMap(
      await _client.patch(
        '/tasks/$taskId/subtasks/$subtaskId',
        data: input.toJson(),
      ),
    );
    return Subtask.fromJson(data);
  }
}

class ApiCityRepository implements CityRepository {
  ApiCityRepository(this._client);

  final ApiClient _client;

  @override
  Future<CityState> getCityState() async {
    final CityResponse response = CityResponse.fromJson(
      _asMap(await _client.get('/city')),
    );
    final Set<String> occupied = response.buildings
        .map((Building item) => '${item.positionX}:${item.positionY}')
        .toSet();
    final List<MapPosition> slots = buildMockDecorationSlots()
        .where((MapPosition slot) => !occupied.contains('${slot.x}:${slot.y}'))
        .toList(growable: false);
    return CityState(
      response: response,
      characters: buildMockCharacters(),
      freeDecorationSlots: slots,
    );
  }

  @override
  Future<BuildingPurchaseResponse> purchaseBuilding(
    BuildingCreateRequest request,
  ) async {
    try {
      final Map<String, dynamic> data = _asMap(
        await _client.post('/city/buildings', data: request.toJson()),
      );
      return BuildingPurchaseResponse.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 400 && error.message == 'Insufficient funds') {
        throw const InsufficientCoinsException();
      }
      rethrow;
    }
  }

  @override
  Future<BuildingUpgradeResponse> upgradeBuilding(int buildingId) async {
    try {
      final Map<String, dynamic> data = _asMap(
        await _client.patch('/city/buildings/$buildingId/upgrade'),
      );
      return BuildingUpgradeResponse.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 400 && error.message == 'Insufficient funds') {
        throw const InsufficientCoinsException();
      }
      rethrow;
    }
  }
}

class CoreApiAchievementRepository implements AchievementRepository {
  @override
  Future<List<AchievementProgress>> getAchievementProgress() {
    throw const FeatureUnavailableException(
      'Detailed achievements are not available in core API mode yet.',
    );
  }
}

class CoreApiShopRepository implements ShopRepository {
  CoreApiShopRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ShopItem>> getItems() async {
    final List<dynamic> data = _asList(await _client.get('/shop'));
    return data
        .map((dynamic item) => ShopItem.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  @override
  Future<ShopItem> purchaseItem(int itemId) async {
    try {
      final Map<String, dynamic> data = _asMap(
        await _client.post('/shop/items/$itemId/purchase'),
      );
      return ShopItem.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 400 && error.message == 'Insufficient funds') {
        throw const InsufficientCoinsException();
      }
      rethrow;
    }
  }

  @override
  Future<ShopItem> markPlaced(int itemId, {bool isPlaced = true}) async {
    final Map<String, dynamic> data = _asMap(
      await _client.patch(
        '/shop/items/$itemId/placement',
        data: <String, dynamic>{'is_placed': isPlaced},
      ),
    );
    return ShopItem.fromJson(data);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  return Map<String, dynamic>.from(value as Map);
}

List<dynamic> _asList(dynamic value) {
  return List<dynamic>.from(value as List);
}
