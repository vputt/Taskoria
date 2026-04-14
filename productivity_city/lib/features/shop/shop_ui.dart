import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';

extension ShopItemTypePresentation on ShopItemType {
  String get label {
    switch (this) {
      case ShopItemType.decoration:
        return 'Декор';
      case ShopItemType.character:
        return 'Персонаж';
      case ShopItemType.special:
        return 'Особый предмет';
    }
  }

  String get filterLabel {
    switch (this) {
      case ShopItemType.decoration:
        return 'Декор';
      case ShopItemType.character:
        return 'Персонажи';
      case ShopItemType.special:
        return 'Особое';
    }
  }

  Color get accentColor {
    switch (this) {
      case ShopItemType.decoration:
        return AppColors.categoryHealth;
      case ShopItemType.character:
        return AppColors.categoryPersonal;
      case ShopItemType.special:
        return AppColors.categoryWork;
    }
  }

  bool get isPlaceable => this == ShopItemType.decoration;
}

String assetPathForShopAsset(String assetId) {
  switch (assetId) {
    case 'bowling':
      return AssetPaths.cityDecorationBowling;
    case 'shooting_range':
      return AssetPaths.cityDecorationShootingRange;
    case 'donut_van':
      return AssetPaths.cityDecorationDonutVan;
    case 'cinema':
      return AssetPaths.cityDecorationCinema;
    default:
      return AssetPaths.plusBadge;
  }
}

String statusLabelForShopItem(ShopItem item) {
  if (!item.isOwned) {
    return 'Доступно';
  }
  if (item.type.isPlaceable) {
    return item.isPlaced ? 'Размещено' : 'В инвентаре';
  }
  return 'В коллекции';
}
