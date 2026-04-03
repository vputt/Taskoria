import 'package:flutter/material.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';

class CityPlacedItemSpec {
  const CityPlacedItemSpec({
    required this.assetId,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.anchorPxX,
    required this.anchorPxY,
    required this.anchorCellX,
    required this.anchorCellY,
    this.layerPriority = 0,
    this.layerDepthBias = 0,
  });

  final String assetId;
  final String assetPath;
  final double width;
  final double height;
  final double sourceWidth;
  final double sourceHeight;
  final double anchorPxX;
  final double anchorPxY;
  final double anchorCellX;
  final double anchorCellY;
  final int layerPriority;
  final double layerDepthBias;

  CityBuildingLevelSpec get levelSpec => CityBuildingLevelSpec(
    level: 1,
    assetPath: assetPath,
    footprintStartX: anchorCellX.round(),
    footprintEndX: anchorCellX.round(),
    footprintStartY: anchorCellY.round(),
    footprintEndY: anchorCellY.round(),
    width: width,
    height: height,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    anchorPxX: anchorPxX,
    anchorPxY: anchorPxY,
    anchorCellX: anchorCellX,
    anchorCellY: anchorCellY,
  );

  static const List<CityPlacedItemSpec> placedItems = <CityPlacedItemSpec>[
    CityPlacedItemSpec(
      assetId: 'bowling',
      assetPath: AssetPaths.cityDecorationBowling,
      width: 284,
      height: 195,
      sourceWidth: 525,
      sourceHeight: 362,
      anchorPxX: 218,
      anchorPxY: 345,
      anchorCellX: 13,
      anchorCellY: 3,
      layerPriority: 1,
    ),
    CityPlacedItemSpec(
      assetId: 'shooting_range',
      assetPath: AssetPaths.cityDecorationShootingRange,
      width: 160,
      height: 108,
      sourceWidth: 296,
      sourceHeight: 200,
      anchorPxX: 124,
      anchorPxY: 173,
      anchorCellX: 6,
      anchorCellY: 25,
    ),
    CityPlacedItemSpec(
      assetId: 'donut_van',
      assetPath: AssetPaths.cityDecorationDonutVan,
      width: 149,
      height: 99,
      sourceWidth: 276,
      sourceHeight: 184,
      anchorPxX: 173,
      anchorPxY: 154,
      anchorCellX: 14,
      anchorCellY: 21,
    ),
    CityPlacedItemSpec(
      assetId: 'cinema',
      assetPath: AssetPaths.cityDecorationCinema,
      width: 224,
      height: 188,
      sourceWidth: 296,
      sourceHeight: 279,
      anchorPxX: 169,
      anchorPxY: 275,
      anchorCellX: 14,
      anchorCellY: 25,
      layerPriority: 1,
    ),
  ];

  static CityPlacedItemSpec? forAssetId(String assetId) {
    for (final CityPlacedItemSpec spec in placedItems) {
      if (spec.assetId == assetId) {
        return spec;
      }
    }
    return null;
  }
}

class CityBuildingSpec {
  const CityBuildingSpec({
    required this.category,
    required this.levelSpecs,
    this.layerDepthBias = 0,
    this.layerPriority = 0,
  });

  final TaskCategory category;
  final List<CityBuildingLevelSpec> levelSpecs;
  final double layerDepthBias;
  final int layerPriority;

  CityBuildingLevelSpec levelSpecFor(int level) {
    return levelSpecs.firstWhere(
      (CityBuildingLevelSpec spec) => spec.level == level,
      orElse: () => levelSpecs.last,
    );
  }

  static const List<CityBuildingSpec> categoryBuildings = <CityBuildingSpec>[
    CityBuildingSpec(
      category: TaskCategory.study,
      layerDepthBias: 260,
      layerPriority: 2,
      levelSpecs: <CityBuildingLevelSpec>[
        CityBuildingLevelSpec(
          level: 1,
          assetPath: AssetPaths.citySchoolLevel1,
          footprintStartX: 7,
          footprintEndX: 10,
          footprintStartY: 4,
          footprintEndY: 12,
          width: 467,
          height: 329,
          sourceWidth: 813,
          sourceHeight: 598,
          anchorPxX: 282,
          anchorPxY: 572,
          anchorCellX: 7,
          anchorCellY: 5,
        ),
        CityBuildingLevelSpec(
          level: 2,
          assetPath: AssetPaths.citySchoolLevel2,
          footprintStartX: 7,
          footprintEndX: 10,
          footprintStartY: 4,
          footprintEndY: 12,
          width: 447,
          height: 348,
          sourceWidth: 764,
          sourceHeight: 618,
          anchorPxX: 270,
          anchorPxY: 553,
          anchorCellX: 7,
          anchorCellY: 5,
        ),
        CityBuildingLevelSpec(
          level: 3,
          assetPath: AssetPaths.citySchoolLevel3,
          footprintStartX: 7,
          footprintEndX: 10,
          footprintStartY: 4,
          footprintEndY: 12,
          width: 429,
          height: 370,
          sourceWidth: 713,
          sourceHeight: 637,
          anchorPxX: 219,
          anchorPxY: 571,
          anchorCellX: 7,
          anchorCellY: 5,
        ),
      ],
    ),
    CityBuildingSpec(
      category: TaskCategory.personal,
      layerPriority: 1,
      levelSpecs: <CityBuildingLevelSpec>[
        CityBuildingLevelSpec(
          level: 1,
          assetPath: AssetPaths.cityPersonalLevel1,
          footprintStartX: 5,
          footprintEndX: 9,
          footprintStartY: 13,
          footprintEndY: 17,
          width: 320,
          height: 276,
          sourceWidth: 547,
          sourceHeight: 472,
          anchorPxX: 274,
          anchorPxY: 468,
          anchorCellX: 7,
          anchorCellY: 17,
        ),
        CityBuildingLevelSpec(
          level: 2,
          assetPath: AssetPaths.cityPersonalLevel2,
          footprintStartX: 7,
          footprintEndX: 9,
          footprintStartY: 13,
          footprintEndY: 20,
          width: 320,
          height: 267,
          sourceWidth: 616,
          sourceHeight: 515,
          anchorPxX: 174,
          anchorPxY: 513,
          anchorCellX: 7,
          anchorCellY: 16,
        ),
        CityBuildingLevelSpec(
          level: 3,
          assetPath: AssetPaths.cityPersonalLevel3,
          footprintStartX: 6,
          footprintEndX: 9,
          footprintStartY: 13,
          footprintEndY: 20,
          width: 374,
          height: 275,
          sourceWidth: 860,
          sourceHeight: 632,
          anchorPxX: 299,
          anchorPxY: 565,
          anchorCellX: 7,
          anchorCellY: 16,
        ),
      ],
    ),
    CityBuildingSpec(
      category: TaskCategory.health,
      levelSpecs: <CityBuildingLevelSpec>[
        CityBuildingLevelSpec(
          level: 1,
          assetPath: AssetPaths.cityHospitalLevel1,
          footprintStartX: 21,
          footprintEndX: 23,
          footprintStartY: 5,
          footprintEndY: 11,
          width: 320,
          height: 273,
          sourceWidth: 604,
          sourceHeight: 516,
          anchorPxX: 217,
          anchorPxY: 513,
          anchorCellX: 22,
          anchorCellY: 5,
        ),
        CityBuildingLevelSpec(
          level: 2,
          assetPath: AssetPaths.cityHospitalLevel2,
          footprintStartX: 21,
          footprintEndX: 23,
          footprintStartY: 3,
          footprintEndY: 14,
          width: 427,
          height: 324,
          sourceWidth: 727,
          sourceHeight: 552,
          anchorPxX: 234,
          anchorPxY: 550,
          anchorCellX: 22,
          anchorCellY: 5,
          offset: Offset(23, 0),
        ),
        CityBuildingLevelSpec(
          level: 3,
          assetPath: AssetPaths.cityHospitalLevel3,
          footprintStartX: 21,
          footprintEndX: 24,
          footprintStartY: 3,
          footprintEndY: 14,
          width: 404,
          height: 332,
          sourceWidth: 669,
          sourceHeight: 550,
          anchorPxX: 176,
          anchorPxY: 548,
          anchorCellX: 22,
          anchorCellY: 5,
          offset: Offset(18, 0),
        ),
      ],
    ),
    CityBuildingSpec(
      category: TaskCategory.work,
      levelSpecs: <CityBuildingLevelSpec>[
        CityBuildingLevelSpec(
          level: 1,
          assetPath: AssetPaths.cityOfficeLevel1,
          footprintStartX: 21,
          footprintEndX: 23,
          footprintStartY: 15,
          footprintEndY: 20,
          width: 280,
          height: 253,
          sourceWidth: 510,
          sourceHeight: 461,
          anchorPxX: 181,
          anchorPxY: 459,
          anchorCellX: 21,
          anchorCellY: 17,
        ),
        CityBuildingLevelSpec(
          level: 2,
          assetPath: AssetPaths.cityOfficeLevel2,
          footprintStartX: 21,
          footprintEndX: 23,
          footprintStartY: 15,
          footprintEndY: 20,
          width: 292,
          height: 271,
          sourceWidth: 496,
          sourceHeight: 461,
          anchorPxX: 164,
          anchorPxY: 459,
          anchorCellX: 21,
          anchorCellY: 17,
        ),
        CityBuildingLevelSpec(
          level: 3,
          assetPath: AssetPaths.cityOfficeLevel3,
          footprintStartX: 21,
          footprintEndX: 24,
          footprintStartY: 15,
          footprintEndY: 21,
          width: 310,
          height: 207,
          sourceWidth: 619,
          sourceHeight: 413,
          anchorPxX: 221,
          anchorPxY: 410,
          anchorCellX: 22,
          anchorCellY: 17,
        ),
      ],
    ),
  ];

  static const CityBuildingLevelSpec townHall = CityBuildingLevelSpec(
    level: 1,
    assetPath: AssetPaths.cityTownHall,
    footprintStartX: 13,
    footprintEndX: 16,
    footprintStartY: 10,
    footprintEndY: 16,
    width: 350,
    height: 350,
    sourceWidth: 630,
    sourceHeight: 630,
    anchorPxX: 243,
    anchorPxY: 559,
    anchorCellX: 14,
    anchorCellY: 11,
  );
}

class CityBuildingLevelSpec {
  const CityBuildingLevelSpec({
    required this.level,
    required this.assetPath,
    required this.footprintStartX,
    required this.footprintEndX,
    required this.footprintStartY,
    required this.footprintEndY,
    required this.width,
    required this.height,
    this.sourceWidth,
    this.sourceHeight,
    this.anchorPxX,
    this.anchorPxY,
    this.anchorCellX,
    this.anchorCellY,
    this.offset = Offset.zero,
  });

  final int level;
  final String assetPath;
  final int footprintStartX;
  final int footprintEndX;
  final int footprintStartY;
  final int footprintEndY;
  final double width;
  final double height;
  final double? sourceWidth;
  final double? sourceHeight;
  final double? anchorPxX;
  final double? anchorPxY;
  final double? anchorCellX;
  final double? anchorCellY;
  final Offset offset;

  bool get hasManualAnchor =>
      anchorPxX != null &&
      anchorPxY != null &&
      anchorCellX != null &&
      anchorCellY != null;

  double get anchorX => (footprintStartX + footprintEndX) / 2;
  double get anchorY => (footprintStartY + footprintEndY) / 2;
  double get layerDepth => anchorX + anchorY;
}
