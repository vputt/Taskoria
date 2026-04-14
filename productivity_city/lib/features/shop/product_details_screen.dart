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
import 'package:productivity_city/shared/providers/repositories.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? parsedProductId = int.tryParse(productId);
    if (parsedProductId == null) {
      return _ProductPageShell(
        title: 'Предмет',
        child: _ProductStateCard(
          title: 'Не удалось открыть предмет',
          description: 'Маршрут передал некорректный идентификатор товара.',
          actionLabel: 'Вернуться в магазин',
          onAction: () => context.go('/shop'),
        ),
      );
    }

    final AsyncValue<UserProfile> userAsync = ref.watch(effectiveUserProvider);
    final AsyncValue<List<ShopItem>> shopAsync = ref.watch(shopProvider);

    return _ProductPageShell(
      title: 'Предмет',
      onBack: () => _handleBack(context),
      child: userAsync.when(
        loading: () => const _ProductLoadingState(),
        error: (Object error, StackTrace stackTrace) => _ProductStateCard(
          title: 'Не удалось загрузить баланс',
          description: 'Нужно подтянуть профиль перед покупкой предмета.',
          actionLabel: 'Повторить',
          onAction: () => ref.invalidate(userProvider),
        ),
        data: (UserProfile user) => shopAsync.when(
          loading: () => const _ProductLoadingState(),
          error: (Object error, StackTrace stackTrace) => _ProductStateCard(
            title: 'Не удалось загрузить витрину',
            description:
                'Предметы магазина не подгрузились. Повтори запрос и попробуем снова.',
            actionLabel: 'Повторить',
            onAction: () => ref.invalidate(shopProvider),
          ),
          data: (List<ShopItem> items) {
            final ShopItem? item = items.cast<ShopItem?>().firstWhere(
              (ShopItem? candidate) => candidate?.id == parsedProductId,
              orElse: () => null,
            );
            if (item == null) {
              return _ProductStateCard(
                title: 'Предмет не найден',
                description:
                    'Возможно, его больше нет в текущем наборе mock-данных.',
                actionLabel: 'Вернуться в магазин',
                onAction: () => context.go('/shop'),
              );
            }
            return _ProductBody(item: item, user: user);
          },
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/shop');
  }
}

class _ProductBody extends ConsumerWidget {
  const _ProductBody({required this.item, required this.user});

  final ShopItem item;
  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool canAfford = user.coins >= item.price;
    final String assetPath = assetPathForShopAsset(item.assetId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: item.type.accentColor.withValues(alpha: 0.18),
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 280,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: PixelImage(
                      assetPath,
                      width: item.assetId == 'plus_badge' ? 120 : 180,
                      height: item.assetId == 'plus_badge' ? 120 : 180,
                    ),
                  ),
                  if (item.isOwned)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          borderRadius: AppRadius.chip,
                        ),
                        child: Text(
                          statusLabelForShopItem(item),
                          style: AppTextStyles.tiny.copyWith(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppTheme.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: item.type.accentColor.withValues(alpha: 0.2),
                      borderRadius: AppRadius.chip,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      child: Text(
                        item.type.label,
                        style: AppTextStyles.tiny.copyWith(
                          color: AppColors.accentBrownDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.name, style: AppTextStyles.display),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _InfoCard(
                  label: 'Цена',
                  child: Row(
                    children: <Widget>[
                      const PixelImage(AssetPaths.coin, width: 20, height: 20),
                      const SizedBox(width: 6),
                      Text('${item.price}', style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoCard(
                  label: 'Баланс',
                  child: Text(
                    '${user.coins}',
                    style: AppTextStyles.subtitle.copyWith(
                      color: canAfford || item.isOwned
                          ? AppColors.accentBrownDark
                          : AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (item.isOwned && item.type.isPlaceable)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _togglePlacement(context, ref, item),
                child: Text(
                  item.isPlaced ? 'Убрать с карты' : 'Пометить для карты',
                ),
              ),
            )
          else if (item.isOwned)
            const _OwnedBanner()
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canAfford
                    ? () => _purchase(context, ref, item)
                    : null,
                child: Text(
                  canAfford
                      ? 'Купить за ${item.price} монет'
                      : 'Недостаточно монет',
                ),
              ),
            ),
          if (!item.isOwned && !canAfford) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Не хватает ${item.price - user.coins} монет.',
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
  ) async {
    try {
      await ref.read(shopProvider.notifier).purchaseItem(item.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Предмет "${item.name}" куплен.')));
    } on InsufficientCoinsException {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Монет пока недостаточно.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось завершить покупку. Попробуй еще раз.'),
        ),
      );
    }
  }

  Future<void> _togglePlacement(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
  ) async {
    try {
      await ref
          .read(shopProvider.notifier)
          .markPlaced(item.id, isPlaced: !item.isPlaced);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isPlaced
                ? 'Предмет убран из карты.'
                : 'Предмет помечен для карты.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось обновить состояние предмета.'),
        ),
      );
    }
  }
}

class _ProductPageShell extends StatelessWidget {
  const _ProductPageShell({
    required this.title,
    required this.child,
    this.onBack,
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(title),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: 8,
            bottom: 8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            child,
          ],
        ),
      ),
    );
  }
}

class _OwnedBanner extends StatelessWidget {
  const _OwnedBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE2ECD3),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.success),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Этот предмет уже есть в коллекции.')),
          ],
        ),
      ),
    );
  }
}

class _ProductStateCard extends StatelessWidget {
  const _ProductStateCard({
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

class _ProductLoadingState extends StatelessWidget {
  const _ProductLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        children: List<Widget>.generate(
          4,
          (int index) => Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : AppSpacing.md),
            child: Container(
              width: double.infinity,
              height: index == 0 ? 280 : 132,
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
