import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/session/session_state.dart';

enum DataSourceKind { mock, coreApi }

class SubtasksAlreadyExistException implements Exception {
  const SubtasksAlreadyExistException();

  @override
  String toString() => 'Subtasks already exist. Recreate?';
}

class InsufficientCoinsException implements Exception {
  const InsufficientCoinsException();

  @override
  String toString() => 'Not enough coins to complete the purchase.';
}

abstract interface class UserRepository {
  Future<UserProfile> getCurrentUser();
}

abstract interface class AuthRepository {
  Future<void> register({
    required String email,
    required String username,
    required String password,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession?> restoreSession();
  Future<void> logout();
}

abstract interface class TaskRepository {
  Future<List<Task>> getTasks({TaskStatus? status, TaskCategory? category});

  Future<TaskWithSubtasks> getTask(int taskId);
  Future<Task> createTask(TaskCreateInput input);
  Future<Task> updateTask(int taskId, TaskUpdateInput input);
  Future<void> deleteTask(int taskId);
  Future<TaskCompleteResult> completeTask(int taskId);
  Future<List<Subtask>> splitTask(int taskId, {bool replaceExisting = false});
  Future<Subtask> updateSubtask(
    int taskId,
    int subtaskId,
    SubtaskUpdateInput input,
  );
}

abstract interface class CityRepository {
  Future<CityState> getCityState();
  Future<BuildingPurchaseResponse> purchaseBuilding(
    BuildingCreateRequest request,
  );
  Future<BuildingUpgradeResponse> upgradeBuilding(int buildingId);
}

abstract interface class AchievementRepository {
  Future<List<AchievementProgress>> getAchievementProgress();
}

abstract interface class ShopRepository {
  Future<List<ShopItem>> getItems();
  Future<ShopItem> purchaseItem(int itemId);
  Future<ShopItem> markPlaced(int itemId, {bool isPlaced = true});
}
