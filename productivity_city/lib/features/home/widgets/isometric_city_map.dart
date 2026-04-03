import 'package:flutter/material.dart';
import 'package:productivity_city/features/home/widgets/city_map_specs.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';

class IsometricCityMap extends StatefulWidget {
  const IsometricCityMap({
    required this.cityState,
    required this.placedItems,
    required this.onBuildingTap,
    required this.onTownHallTap,
    super.key,
  });

  final CityState cityState;
  final List<ShopItem> placedItems;
  final ValueChanged<Building> onBuildingTap;
  final VoidCallback onTownHallTap;

  @override
  State<IsometricCityMap> createState() => _IsometricCityMapState();
}

class _IsometricCityMapState extends State<IsometricCityMap> {
  final TransformationController _controller = TransformationController();
  Size? _lastViewportSize;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<TaskCategory, Building> buildingsByCategory =
        <TaskCategory, Building>{
          for (final Building building in widget.cityState.response.buildings)
            building.category: building,
        };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewportSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        _scheduleInitialTransform(viewportSize);

        return ClipRect(
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            minScale: 0.58,
            maxScale: 1.22,
            boundaryMargin: const EdgeInsets.all(360),
            child: SizedBox(
              width: _IsoCityMetrics.mapWidth,
              height: _IsoCityMetrics.mapHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFEEF0EA)),
                    ),
                  ),
                  ..._CityTileLayer.tiles,
                  ..._buildCityNodes(
                    buildingsByCategory,
                    widget.placedItems,
                    widget.onBuildingTap,
                    widget.onTownHallTap,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCityNodes(
    Map<TaskCategory, Building> buildingsByCategory,
    List<ShopItem> placedItems,
    ValueChanged<Building> onBuildingTap,
    VoidCallback onTownHallTap,
  ) {
    final List<_CityLayerEntry> entries = <_CityLayerEntry>[
      for (final CityBuildingSpec spec in CityBuildingSpec.categoryBuildings)
        _CityLayerEntry.building(
          spec: spec,
          building: buildingsByCategory[spec.category],
          onTap: onBuildingTap,
        ),
      for (final ShopItem item in placedItems)
        if (CityPlacedItemSpec.forAssetId(item.assetId)
            case final CityPlacedItemSpec spec)
          _CityLayerEntry.placedItem(spec: spec),
      _CityLayerEntry.townHall(onTap: onTownHallTap),
    ];

    entries.sort(_CityLayerEntry.compare);
    return entries.map((_CityLayerEntry entry) => entry.child).toList();
  }

  void _scheduleInitialTransform(Size viewportSize) {
    if (_lastViewportSize == viewportSize) {
      return;
    }
    _lastViewportSize = viewportSize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final double scale = (viewportSize.width / 560).clamp(0.64, 0.86);
      const double targetX = _IsoCityMetrics.mapWidth * 0.52;
      const double targetY = _IsoCityMetrics.mapHeight * 0.48;
      final double dx = viewportSize.width / 2 - targetX * scale;
      final double dy = viewportSize.height * 0.44 - targetY * scale;

      _controller.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, scale, 1);
    });
  }
}

class _CityLayerEntry {
  _CityLayerEntry({
    required this.child,
    required this.depth,
    required this.priority,
  });

  factory _CityLayerEntry.building({
    required CityBuildingSpec spec,
    required Building? building,
    required ValueChanged<Building> onTap,
  }) {
    final CityBuildingLevelSpec levelSpec = spec.levelSpecFor(
      _displayLevelFor(building),
    );
    final Rect footprintBounds = _IsoCityMetrics.footprintBounds(levelSpec);
    return _CityLayerEntry(
      child: _CityBuildingNode(spec: spec, building: building, onTap: onTap),
      depth: footprintBounds.bottom + spec.layerDepthBias,
      priority: spec.layerPriority,
    );
  }

  factory _CityLayerEntry.townHall({required VoidCallback onTap}) {
    const CityBuildingLevelSpec levelSpec = CityBuildingSpec.townHall;
    final Rect footprintBounds = _IsoCityMetrics.footprintBounds(levelSpec);
    return _CityLayerEntry(
      child: _TownHallNode(onTap: onTap),
      depth: footprintBounds.bottom,
      priority: 0,
    );
  }

  factory _CityLayerEntry.placedItem({required CityPlacedItemSpec spec}) {
    final Offset anchor = _IsoCityMetrics.cellBottomCorner(
      spec.anchorCellX,
      spec.anchorCellY,
    );
    return _CityLayerEntry(
      child: _PlacedItemNode(spec: spec),
      depth: anchor.dy + spec.layerDepthBias,
      priority: spec.layerPriority,
    );
  }

  final Widget child;
  final double depth;
  final int priority;

  static int compare(_CityLayerEntry a, _CityLayerEntry b) {
    final int depthCompare = a.depth.compareTo(b.depth);
    if (depthCompare != 0) {
      return depthCompare;
    }
    return a.priority.compareTo(b.priority);
  }
}

class _CityTileLayer {
  static final List<Widget> tiles = _buildTiles();

  static List<Widget> _buildTiles() {
    final Set<_RoadBlock> roads = _buildRoadBlocks();
    final List<Widget> result = <Widget>[];

    for (int diagonal = 0; diagonal <= 26; diagonal++) {
      for (int blockX = 0; blockX < 14; blockX++) {
        final int blockY = diagonal - blockX;
        if (blockY < 0 || blockY >= 14) {
          continue;
        }
        final _RoadBlock block = _RoadBlock(blockX, blockY);
        final Offset topLeft = _IsoCityMetrics.blockTopLeft(blockX, blockY);
        result.add(
          Positioned(
            left: topLeft.dx - _IsoCityMetrics.tileOverlap,
            top: topLeft.dy - _IsoCityMetrics.tileOverlap,
            child: Image.asset(
              _tileAsset(block, roads),
              width:
                  _IsoCityMetrics.blockWidth + _IsoCityMetrics.tileOverlap * 2,
              height:
                  _IsoCityMetrics.blockHeight + _IsoCityMetrics.tileOverlap * 2,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }
    }

    return result;
  }

  static String _tileAsset(_RoadBlock block, Set<_RoadBlock> roads) {
    if (!roads.contains(block)) {
      return AssetPaths.cityGrass2x2;
    }

    final bool left = roads.contains(_RoadBlock(block.x - 1, block.y));
    final bool right = roads.contains(_RoadBlock(block.x + 1, block.y));
    final bool up = roads.contains(_RoadBlock(block.x, block.y - 1));
    final bool down = roads.contains(_RoadBlock(block.x, block.y + 1));
    final int xLinks = (left ? 1 : 0) + (right ? 1 : 0);
    final int yLinks = (up ? 1 : 0) + (down ? 1 : 0);
    final int degree = xLinks + yLinks;

    if (xLinks > 0 && yLinks > 0) {
      return degree >= 4 ? AssetPaths.cityRoadCross : AssetPaths.cityRoadSplit;
    }
    if (xLinks > 0) {
      return AssetPaths.cityRoadTowards;
    }
    return AssetPaths.cityRoadForward;
  }

  static Set<_RoadBlock> _buildRoadBlocks() {
    final Set<_RoadBlock> roads = <_RoadBlock>{};

    void addCellRoad(int x, int y) {
      roads.add(_RoadBlock((x - 1) ~/ 2, (y - 1) ~/ 2));
    }

    for (int y = 1; y <= 28; y += 2) {
      addCellRoad(9, y);
      addCellRoad(17, y);
    }
    for (int x = 9; x <= 17; x += 2) {
      addCellRoad(x, 9);
    }
    for (int x = 17; x <= 28; x += 2) {
      addCellRoad(x, 15);
    }
    for (int x = 1; x <= 28; x += 2) {
      addCellRoad(x, 23);
    }

    return roads;
  }
}

class _CityBuildingNode extends StatelessWidget {
  const _CityBuildingNode({
    required this.spec,
    required this.building,
    required this.onTap,
  });

  final CityBuildingSpec spec;
  final Building? building;
  final ValueChanged<Building> onTap;

  @override
  Widget build(BuildContext context) {
    final int displayLevel = _displayLevelFor(building);
    final CityBuildingLevelSpec levelSpec = spec.levelSpecFor(displayLevel);
    final Offset topLeft = _resolveTopLeft(levelSpec);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      left: topLeft.dx,
      top: topLeft.dy,
      width: levelSpec.width,
      height: levelSpec.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: building == null ? null : () => onTap(building!),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: Image.asset(
            levelSpec.assetPath,
            key: ValueKey<String>(levelSpec.assetPath),
            width: levelSpec.width,
            height: levelSpec.height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }
}

int _displayLevelFor(Building? building) {
  return (building?.level ?? 1).clamp(1, 3);
}

Offset _resolveTopLeft(CityBuildingLevelSpec levelSpec) {
  if (levelSpec.hasManualAnchor) {
    final Offset mapAnchor = _IsoCityMetrics.cellBottomCorner(
      levelSpec.anchorCellX!,
      levelSpec.anchorCellY!,
    );
    final double scaleX = levelSpec.sourceWidth == null
        ? 1
        : levelSpec.width / levelSpec.sourceWidth!;
    final double scaleY = levelSpec.sourceHeight == null
        ? 1
        : levelSpec.height / levelSpec.sourceHeight!;
    return Offset(
      mapAnchor.dx - levelSpec.anchorPxX! * scaleX + levelSpec.offset.dx,
      mapAnchor.dy - levelSpec.anchorPxY! * scaleY + levelSpec.offset.dy,
    );
  }

  final Rect footprintBounds = _IsoCityMetrics.footprintBounds(levelSpec);
  return Offset(
    footprintBounds.center.dx - levelSpec.width / 2 + levelSpec.offset.dx,
    footprintBounds.bottom - levelSpec.height + levelSpec.offset.dy,
  );
}

class _TownHallNode extends StatelessWidget {
  const _TownHallNode({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const CityBuildingLevelSpec levelSpec = CityBuildingSpec.townHall;
    final Offset topLeft = _resolveTopLeft(levelSpec);

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: levelSpec.width,
      height: levelSpec.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Image.asset(
          levelSpec.assetPath,
          width: levelSpec.width,
          height: levelSpec.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _PlacedItemNode extends StatelessWidget {
  const _PlacedItemNode({required this.spec});

  final CityPlacedItemSpec spec;

  @override
  Widget build(BuildContext context) {
    final Offset topLeft = _resolveTopLeft(spec.levelSpec);

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: spec.levelSpec.width,
      height: spec.levelSpec.height,
      child: IgnorePointer(
        child: Image.asset(
          spec.levelSpec.assetPath,
          width: spec.levelSpec.width,
          height: spec.levelSpec.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}

class _IsoCityMetrics {
  static const int cellCount = 28;
  static const int blockCount = cellCount ~/ 2;
  static const double blockWidth = 128;
  static const double blockHeight = 74;
  static const double tileOverlap = 1.35;
  static const double cellStepX = blockWidth / 4;
  static const double cellStepY = blockHeight / 4;
  static const double mapWidth = blockWidth * blockCount;
  static const double mapHeight = 1160;
  static const Offset origin = Offset(mapWidth / 2, 42);

  static Offset blockTopLeft(int blockX, int blockY) {
    final _RoadBlock rotatedBlock = _rotateBlock(blockX, blockY);
    final Offset top = Offset(
      origin.dx + (rotatedBlock.y - rotatedBlock.x) * (blockWidth / 2),
      origin.dy + (rotatedBlock.x + rotatedBlock.y) * (blockHeight / 2),
    );
    return Offset(top.dx - blockWidth / 2, top.dy);
  }

  static Rect footprintBounds(CityBuildingLevelSpec spec) {
    final List<Offset> corners = <Offset>[
      cellCorner(
        spec.footprintStartX.toDouble(),
        spec.footprintStartY.toDouble(),
      ),
      cellCorner(
        (spec.footprintEndX + 1).toDouble(),
        spec.footprintStartY.toDouble(),
      ),
      cellCorner(
        (spec.footprintEndX + 1).toDouble(),
        (spec.footprintEndY + 1).toDouble(),
      ),
      cellCorner(
        spec.footprintStartX.toDouble(),
        (spec.footprintEndY + 1).toDouble(),
      ),
    ];

    double left = corners.first.dx;
    double right = corners.first.dx;
    double top = corners.first.dy;
    double bottom = corners.first.dy;

    for (final Offset corner in corners.skip(1)) {
      left = corner.dx < left ? corner.dx : left;
      right = corner.dx > right ? corner.dx : right;
      top = corner.dy < top ? corner.dy : top;
      bottom = corner.dy > bottom ? corner.dy : bottom;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Offset cellBottomCorner(double x, double y) {
    final Offset rotatedCell = _rotateCell(x, y);
    final Offset top = Offset(
      origin.dx + (rotatedCell.dy - rotatedCell.dx) * cellStepX,
      origin.dy + (rotatedCell.dx + rotatedCell.dy - 2) * cellStepY,
    );
    return top + const Offset(0, blockHeight / 2);
  }

  static Offset cellCorner(double x, double y) {
    final Offset rotatedCell = _rotateCell(x, y);
    return Offset(
      origin.dx + (rotatedCell.dy - rotatedCell.dx) * cellStepX,
      origin.dy + (rotatedCell.dx + rotatedCell.dy - 2) * cellStepY,
    );
  }

  static _RoadBlock _rotateBlock(int blockX, int blockY) {
    return _RoadBlock(blockCount - 1 - blockY, blockX);
  }

  static Offset _rotateCell(double x, double y) {
    return Offset(cellCount + 1 - y, x);
  }
}

class _RoadBlock {
  const _RoadBlock(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return other is _RoadBlock && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
