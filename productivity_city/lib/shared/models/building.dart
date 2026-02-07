import 'package:productivity_city/shared/models/enums.dart';

class MapPosition {
  const MapPosition({required this.x, required this.y});

  final int x;
  final int y;

  MapPosition copyWith({int? x, int? y}) {
    return MapPosition(x: x ?? this.x, y: y ?? this.y);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'position_x': x, 'position_y': y};
  }
}

class Building {
  const Building({
    required this.id,
    required this.userId,
    required this.buildingType,
    required this.category,
    required this.positionX,
    required this.positionY,
    required this.level,
    required this.builtAt,
    this.upgradedAt,
  });

  final int id;
  final int userId;
  final String buildingType;
  final TaskCategory category;
  final int positionX;
  final int positionY;
  final int level;
  final DateTime builtAt;
  final DateTime? upgradedAt;

  MapPosition get mapPosition => MapPosition(x: positionX, y: positionY);

  Building copyWith({
    int? id,
    int? userId,
    String? buildingType,
    TaskCategory? category,
    int? positionX,
    int? positionY,
    int? level,
    DateTime? builtAt,
    DateTime? upgradedAt,
  }) {
    return Building(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      buildingType: buildingType ?? this.buildingType,
      category: category ?? this.category,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      level: level ?? this.level,
      builtAt: builtAt ?? this.builtAt,
      upgradedAt: upgradedAt ?? this.upgradedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'building_type': buildingType,
      'category': category.apiValue,
      'position_x': positionX,
      'position_y': positionY,
      'level': level,
      'built_at': builtAt.toIso8601String(),
      'upgraded_at': upgradedAt?.toIso8601String(),
    };
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      buildingType: json['building_type'] as String,
      category: TaskCategory.fromApi(json['category'] as String),
      positionX: json['position_x'] as int,
      positionY: json['position_y'] as int,
      level: json['level'] as int,
      builtAt: DateTime.parse(json['built_at'] as String),
      upgradedAt: json['upgraded_at'] == null
          ? null
          : DateTime.parse(json['upgraded_at'] as String),
    );
  }
}

class BuildingCreateRequest {
  const BuildingCreateRequest({
    required this.buildingType,
    required this.positionX,
    required this.positionY,
  });

  final String buildingType;
  final int positionX;
  final int positionY;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'building_type': buildingType,
      'position_x': positionX,
      'position_y': positionY,
    };
  }
}

class BuildingPurchaseResponse {
  const BuildingPurchaseResponse({
    required this.building,
    required this.cost,
    required this.balanceAfter,
  });

  final Building building;
  final int cost;
  final int balanceAfter;

  factory BuildingPurchaseResponse.fromJson(Map<String, dynamic> json) {
    return BuildingPurchaseResponse(
      building: Building.fromJson(
        Map<String, dynamic>.from(json['building'] as Map),
      ),
      cost: json['cost'] as int,
      balanceAfter: json['balance_after'] as int,
    );
  }
}

class BuildingUpgradeResponse {
  const BuildingUpgradeResponse({
    required this.building,
    required this.cost,
    required this.newLevel,
    required this.balanceAfter,
  });

  final Building building;
  final int cost;
  final int newLevel;
  final int balanceAfter;

  factory BuildingUpgradeResponse.fromJson(Map<String, dynamic> json) {
    return BuildingUpgradeResponse(
      building: Building.fromJson(
        Map<String, dynamic>.from(json['building'] as Map),
      ),
      cost: json['cost'] as int,
      newLevel: json['new_level'] as int,
      balanceAfter: json['balance_after'] as int,
    );
  }
}
