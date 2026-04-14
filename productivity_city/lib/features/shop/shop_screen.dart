import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/features/shop/shop_ui.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ShopItemType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<UserProfile> userAsync = ref.watch(effectiveUserProvider);

    final AsyncValue<List<ShopItem>> shopAsync = ref.watch(shopProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        bottom: false,
        child: userAsync.when(
          loading: () => const _ShopLoadingState(),
          error: (Object error, StackTrace stackTrace) => _ShopStateCard(
            title: 'Не удалось загрузить баланс',
            description: 'Сначала подтянем профиль, потом уже соберем витрину.',
            actionLabel: 'Повторить',
            onAction: () => ref.invalidate(userProvider),
          ),
          data: (UserProfile user) => shopAsync.when(
            loading: () => const _ShopLoadingState(),
            error: (Object error, StackTrace stackTrace) => _ShopStateCard(
              title: 'Не удалось открыть магазин',
              description:
                  'Попробуй повторить запрос. Предметы должны подтянуться из текущего mock-store.',
              actionLabel: 'Повторить',
              onAction: () => ref.invalidate(shopProvider),
            ),
            data: (List<ShopItem> items) =>
                _buildDataState(context, user, items),
          ),
        ),
      ),
    );
  }

  Widget _buildDataState(
    BuildContext context,
    UserProfile user,
    List<ShopItem> items,
  ) {
    final List<ShopItem> filteredItems = _selectedType == null
        ? items
        : items
              .where((ShopItem item) => item.type == _selectedType)
              .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Магазин', style: AppTextStyles.display)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const PixelImage(
                        AssetPaths.coinSmall,
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.coins}',
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.accentBrownDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Укрась город', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Персонажи, украшения и специальные предметы собраны в одном месте.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const SizedBox(
                    width: 112,
                    height: 92,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: PixelImage(
                            AssetPaths.tree,
                            width: 42,
                            height: 42,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 4,
                          child: PixelImage(
                            AssetPaths.hero,
                            width: 42,
                            height: 42,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: PixelImage(
                            AssetPaths.plusBadge,
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _FilterChipButton(
                  label: 'Все',
                  selected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                ...ShopItemType.values.map(
                  (ShopItemType type) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChipButton(
                      label: type.filterLabel,
                      selected: _selectedType == type,
                      onTap: () => setState(() => _selectedType = type),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filteredItems.isEmpty)
            const _ShopEmptyState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 244,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopItem item = filteredItems[index];
                return _ShopItemCard(
                  item: item,
                  onTap: () => context.push('/shop/${item.id}'),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item, required this.onTap});

  final ShopItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String assetPath = assetPathForShopAsset(item.assetId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: item.type.accentColor.withValues(alpha: 0.18),
                      borderRadius: AppRadius.card,
                    ),
                    child: Stack(
                      children: <Widget>[
                        Center(
                          child: PixelImage(
                            assetPath,
                            width: item.assetId == 'plus_badge' ? 52 : 78,
                            height: item.assetId == 'plus_badge' ? 52 : 78,
                          ),
                        ),
                        if (item.isOwned)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                borderRadius: AppRadius.chip,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (item.isOwned)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: item.type.isPlaceable && item.isPlaced
                          ? const Color(0xFFE2ECD3)
                          : AppColors.surfaceSecondary,
                      borderRadius: AppRadius.card,
                    ),
                    child: Center(
                      child: Text(
                        statusLabelForShopItem(item),
                        style: AppTextStyles.tiny.copyWith(
                          color: item.type.isPlaceable && item.isPlaced
                              ? AppColors.success
                              : AppColors.accentBrownDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: AppRadius.card,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const PixelImage(
                          AssetPaths.coinSmall,
                          width: 12,
                          height: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.accentBrownDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.chip,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentOliveDark
                : AppColors.surfacePrimary,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: selected
                  ? AppColors.accentOliveDark
                  : AppColors.borderSoft,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.textOnDark : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopEmptyState extends StatelessWidget {
  const _ShopEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            Image.asset(
              AssetPaths.emptyState,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Ничего не найдено', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Попробуй сбросить фильтр и посмотреть всю витрину.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopStateCard extends StatelessWidget {
  const _ShopStateCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopLoadingState extends StatelessWidget {
  const _ShopLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        120,
      ),
      child: Column(
        children: List<Widget>.generate(
          5,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: index == 0 ? 70 : (index == 1 ? 148 : 244),
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary.withValues(alpha: 0.86),
                borderRadius: AppRadius.card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
