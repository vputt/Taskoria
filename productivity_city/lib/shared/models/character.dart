import 'package:productivity_city/shared/models/building.dart';

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.assetId,
    required this.position,
    required this.message,
  });

  final int id;
  final String name;
  final String assetId;
  final MapPosition position;
  final String message;

  Character copyWith({
    int? id,
    String? name,
    String? assetId,
    MapPosition? position,
    String? message,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      assetId: assetId ?? this.assetId,
      position: position ?? this.position,
      message: message ?? this.message,
    );
  }
}
