import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_city/shared/models/models.dart';

void main() {
  test('task models round-trip json and tolerate legacy completion keys', () {
    final DateTime createdAt = DateTime(2026, 5, 20, 10);
    final DateTime updatedAt = DateTime(2026, 5, 20, 11);
    final Map<String, dynamic> json = <String, dynamic>{
      'id': 10,
      'user_id': 1,
      'title': 'Prepare defense',
      'description': 'Slides and demo',
      'category': TaskCategory.study.apiValue,
      'priority': TaskPriority.high.apiValue,
      'deadline': DateTime(2026, 5, 25).toIso8601String(),
      'status': TaskStatus.inProgress.apiValue,
      'difficulty': TaskDifficulty.hard.apiValue,
      'xp_reward': 180,
      'coins_reward': 60,
      'created_at': createdAt.toIso8601String(),
      'completed_at': null,
      'updated_at': updatedAt.toIso8601String(),
    };

    final Task task = Task.fromJson(json);

    expect(task.id, 10);
    expect(task.category, TaskCategory.study);
    expect(task.priority, TaskPriority.high);
    expect(task.status, TaskStatus.inProgress);
    expect(task.difficulty, TaskDifficulty.hard);
    expect(task.toJson()['title'], 'Prepare defense');

    final TaskCompleteResult result =
        TaskCompleteResult.fromJson(<String, dynamic>{
          'task': json,
          'xp_gained': 180,
          'coins_gained': 60,
          'level_up': true,
          'new_level': 4,
          'streak': 6,
        });

    expect(result.task.title, 'Prepare defense');
    expect(result.xpEarned, 180);
    expect(result.coinsEarned, 60);
    expect(result.levelUp, isTrue);
  });

  test('task with subtasks serializes nested subtask data', () {
    final TaskWithSubtasks task = TaskWithSubtasks.fromJson(<String, dynamic>{
      'id': 11,
      'user_id': 1,
      'title': 'Split work',
      'description': null,
      'category': TaskCategory.work.apiValue,
      'priority': TaskPriority.medium.apiValue,
      'deadline': null,
      'status': TaskStatus.active.apiValue,
      'difficulty': TaskDifficulty.medium.apiValue,
      'xp_reward': 120,
      'coins_reward': 40,
      'created_at': DateTime(2026, 5, 20).toIso8601String(),
      'completed_at': null,
      'updated_at': DateTime(2026, 5, 20, 1).toIso8601String(),
      'subtasks': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 99,
          'task_id': 11,
          'title': 'First step',
          'description': 'Demo',
          'estimated_time': 25,
          'status': SubtaskStatus.notStarted.apiValue,
          'order_index': 0,
        },
      ],
    });

    expect(task.subtasks, hasLength(1));
    expect(task.subtasks.first.title, 'First step');
    expect(task.toTask().id, task.id);
    expect(task.toJson()['subtasks'], isA<List<dynamic>>());
  });

  test('building and city models parse backend shape', () {
    final Map<String, dynamic> buildingJson = <String, dynamic>{
      'id': 5,
      'user_id': 1,
      'building_type': 'library',
      'category': TaskCategory.study.apiValue,
      'position_x': 2,
      'position_y': 3,
      'level': 2,
      'built_at': DateTime(2026, 5, 20).toIso8601String(),
      'upgraded_at': DateTime(2026, 5, 21).toIso8601String(),
    };

    final Building building = Building.fromJson(buildingJson);
    expect(building.mapPosition.x, 2);
    expect(building.mapPosition.y, 3);
    expect(building.copyWith(level: 3).level, 3);

    final CityResponse response = CityResponse.fromJson(<String, dynamic>{
      'user_id': 1,
      'buildings': <Map<String, dynamic>>[buildingJson],
      'total_buildings': 1,
      'total_level': 2,
      'category_breakdown': <String, int>{'study': 1},
      'average_level': 2,
    });

    final CityState state = CityState(
      response: response,
      characters: const <Character>[],
      freeDecorationSlots: const <MapPosition>[MapPosition(x: 1, y: 1)],
    );

    expect(state.buildings.single.id, 5);
    expect(state.response.averageLevel, 2);
    expect(state.freeDecorationSlots.single.toJson()['position_x'], 1);
  });

  test('shop items and enums parse unknown values safely', () {
    final ShopItem item = ShopItem.fromJson(<String, dynamic>{
      'id': 7,
      'name': 'Tree',
      'description': 'Decoration',
      'price': 30,
      'type': ShopItemType.decoration.apiValue,
      'asset_id': 'tree',
      'is_owned': true,
      'is_placed': true,
    });

    expect(item.isOwned, isTrue);
    expect(item.copyWith(isPlaced: false).isPlaced, isFalse);
    expect(item.toJson()['asset_id'], 'tree');

    expect(TaskCategory.fromApi('unknown'), TaskCategory.personal);
    expect(TaskPriority.fromApi('unknown'), TaskPriority.medium);
    expect(TaskStatus.fromApi('unknown'), TaskStatus.active);
    expect(TaskDifficulty.fromApi('unknown'), TaskDifficulty.medium);
    expect(SubtaskStatus.fromApi('unknown'), SubtaskStatus.notStarted);
    expect(ShopItemType.fromApi('unknown'), ShopItemType.decoration);
  });
}
