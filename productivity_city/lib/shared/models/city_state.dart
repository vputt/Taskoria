import 'package:productivity_city/shared/models/building.dart';
import 'package:productivity_city/shared/models/character.dart';

class CityResponse {
  const CityResponse({
    required this.userId,
    required this.buildings,
    required this.totalBuildings,
    required this.totalLevel,
    required this.categoryBreakdown,
    required this.averageLevel,
  });

  final int userId;
  final List<Building> buildings;
  final int totalBuildings;
  final int totalLevel;
  final Map<String, int> categoryBreakdown;
  final double averageLevel;

  CityResponse copyWith({
    int? userId,
    List<Building>? buildings,
    int? totalBuildings,
    int? totalLevel,
    Map<String, int>? categoryBreakdown,
    double? averageLevel,
  }) {
    return CityResponse(
      userId: userId ?? this.userId,
      buildings: buildings ?? this.buildings,
      totalBuildings: totalBuildings ?? this.totalBuildings,
      totalLevel: totalLevel ?? this.totalLevel,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      averageLevel: averageLevel ?? this.averageLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'buildings': buildings
          .map((Building item) => item.toJson())
          .toList(growable: false),
      'total_buildings': totalBuildings,
      'total_level': totalLevel,
      'category_breakdown': categoryBreakdown,
      'average_level': averageLevel,
    };
  }

  factory CityResponse.fromJson(Map<String, dynamic> json) {
    return CityResponse(
      userId: json['user_id'] as int,
      buildings: ((json['buildings'] ?? <dynamic>[]) as List<dynamic>)
          .map(
            (dynamic item) => Building.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      totalBuildings: json['total_buildings'] as int,
      totalLevel: json['total_level'] as int,
      categoryBreakdown: Map<String, int>.from(
        (json['category_breakdown'] ?? <String, int>{}) as Map,
      ),
      averageLevel: (json['average_level'] as num).toDouble(),
    );
  }
}

class CityState {
  const CityState({
    required this.response,
    required this.characters,
    required this.freeDecorationSlots,
  });

  final CityResponse response;
  final List<Character> characters;
  final List<MapPosition> freeDecorationSlots;

  List<Building> get buildings => response.buildings;

  CityState copyWith({
    CityResponse? response,
    List<Character>? characters,
    List<MapPosition>? freeDecorationSlots,
  }) {
    return CityState(
      response: response ?? this.response,
      characters: characters ?? this.characters,
      freeDecorationSlots: freeDecorationSlots ?? this.freeDecorationSlots,
    );
  }
}
