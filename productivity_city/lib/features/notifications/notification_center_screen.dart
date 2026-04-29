import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/models/models.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AppNotification> notifications = ref.watch(
      notificationsProvider,
    );
    final List<AppNotification> unread = notifications
        .where((AppNotification item) => item.isUnread)
        .toList(growable: false);
    final List<AppNotification> earlier = notifications
        .where((AppNotification item) => !item.isUnread)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _HeaderButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Уведомления',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          color: const Color(0xFF70441C),
                        ),
                      ),
                    ),
                    if (notifications.isNotEmpty)
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.surfacePrimary,
                          borderRadius: AppRadius.chip,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          child: Text(
                            '${notifications.length}',
                            style: AppTextStyles.tiny.copyWith(
                              color: AppColors.accentBrownDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: notifications.isEmpty
                      ? const _EmptyNotificationsState()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: <Widget>[
                            if (unread.isNotEmpty) ...<Widget>[
                              Text('Новые', style: AppTextStyles.subtitle),
                              const SizedBox(height: AppSpacing.sm),
                              ...unread.map(
                                (AppNotification item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _NotificationTile(notification: item),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            if (earlier.isNotEmpty) ...<Widget>[
                              Text('Ранее', style: AppTextStyles.subtitle),
                              const SizedBox(height: AppSpacing.sm),
                              ...earlier.map(
                                (AppNotification item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _NotificationTile(notification: item),
                                ),
                              ),
                            ],
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _NotificationIcon(
              kind: notification.kind,
              unread: notification.isUnread,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormat(
                          'dd.MM HH:mm',
                        ).format(notification.createdAt),
                        style: AppTextStyles.tiny,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (notification.taskId != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            context.push('/tasks/${notification.taskId}'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.accentBrownDark,
                        ),
                        child: Text(
                          'Открыть задачу',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBrownDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.kind, required this.unread});

  final AppNotificationKind kind;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final Color background;

    switch (kind) {
      case AppNotificationKind.reminder:
        icon = Icons.schedule_rounded;
        color = AppColors.accentBrownDark;
        background = AppColors.surfaceSecondary;
      case AppNotificationKind.warning:
        icon = Icons.warning_amber_rounded;
        color = AppColors.danger;
        background = const Color(0xFFF9E2DA);
      case AppNotificationKind.reward:
        icon = Icons.workspace_premium_outlined;
        color = AppColors.warning;
        background = const Color(0xFFF9EBCB);
      case AppNotificationKind.info:
        icon = Icons.notifications_none_rounded;
        color = AppColors.accentOliveDark;
        background = const Color(0xFFE5ECD9);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.card,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        if (unread)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.accentGold,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: SizedBox(
        width: 48,
        height: 40,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20, color: AppColors.textPrimary),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppRadius.card,
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.notifications_off_outlined,
                  size: 34,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Пока тихо', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Когда появятся дедлайны, награды и важные события, центр уведомлений заполнится здесь.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
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
