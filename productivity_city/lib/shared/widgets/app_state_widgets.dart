import 'package:flutter/material.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';

class AppStateCard extends StatelessWidget {
  const AppStateCard({
    required this.title,
    required this.description,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                  if (actionLabel != null && onAction != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    required this.itemHeights,
    super.key,
    this.bottomPadding = 120,
  });

  final List<double> itemHeights;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomPadding,
      ),
      child: Column(
        children: List<Widget>.generate(
          itemHeights.length,
          (int index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == itemHeights.length - 1 ? 0 : AppSpacing.md,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary.withValues(alpha: 0.86),
                borderRadius: AppRadius.card,
              ),
              child: SizedBox(
                width: double.infinity,
                height: itemHeights[index],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
