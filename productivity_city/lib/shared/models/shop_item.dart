import 'package:productivity_city/shared/models/enums.dart';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.assetId,
    this.isOwned = false,
    this.isPlaced = false,
  });

  final int id;
  final String name;
  final String description;
  final int price;
  final ShopItemType type;
  final String assetId;
  final bool isOwned;
  final bool isPlaced;

  ShopItem copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    ShopItemType? type,
    String? assetId,
    bool? isOwned,
    bool? isPlaced,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      assetId: assetId ?? this.assetId,
      isOwned: isOwned ?? this.isOwned,
      isPlaced: isPlaced ?? this.isPlaced,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'type': type.apiValue,
      'asset_id': assetId,
      'is_owned': isOwned,
      'is_placed': isPlaced,
    };
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      type: ShopItemType.fromApi(json['type'] as String),
      assetId: json['asset_id'] as String,
      isOwned: (json['is_owned'] ?? false) as bool,
      isPlaced: (json['is_placed'] ?? false) as bool,
    );
  }
}
