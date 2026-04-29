import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_spacing.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/app/theme/app_theme.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _soundsEnabled = true;
  bool _weeklyDigestEnabled = false;
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await ref.read(sessionControllerProvider).logout();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _BackButton(onTap: () => context.pop()),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Настройки', style: AppTextStyles.display),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: 'Уведомления',
                  children: <Widget>[
                    _ToggleTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Push-уведомления',
                      description: 'Напоминания о задачах и дедлайнах',
                      value: _pushEnabled,
                      onChanged: (bool value) {
                        setState(() => _pushEnabled = value);
                      },
                    ),
                    _ToggleTile(
                      icon: Icons.volume_up_outlined,
                      label: 'Звуки',
                      description: 'Подтверждения и игровые сигналы',
                      value: _soundsEnabled,
                      onChanged: (bool value) {
                        setState(() => _soundsEnabled = value);
                      },
                    ),
                    _ToggleTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Еженедельная сводка',
                      description: 'Короткий отчет по прогрессу за неделю',
                      value: _weeklyDigestEnabled,
                      onChanged: (bool value) {
                        setState(() => _weeklyDigestEnabled = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _SettingsSection(
                  title: 'Интерфейс',
                  children: <Widget>[
                    _LinkTile(
                      icon: Icons.palette_outlined,
                      label: 'Тема оформления',
                      value: 'Светлая',
                    ),
                    _LinkTile(
                      icon: Icons.language_outlined,
                      label: 'Язык',
                      value: 'Русский',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsSection(
                  title: 'Аккаунт',
                  children: <Widget>[
                    const _LinkTile(
                      icon: Icons.shield_outlined,
                      label: 'Конфиденциальность',
                    ),
                    const _LinkTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Помощь и поддержка',
                    ),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      label: _isLoggingOut ? 'Выходим...' : 'Выйти',
                      danger: true,
                      enabled: !_isLoggingOut,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: <Widget>[
                      Text('Taskoria 1.0.0', style: AppTextStyles.caption),
                      const SizedBox(height: 2),
                      Text(
                        'Собрано для спокойного ритма и длинной дистанции',
                        style: AppTextStyles.tiny,
                        textAlign: TextAlign.center,
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: AppRadius.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: AppTextStyles.subtitle),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: <Widget>[
            _LeadingIcon(icon: icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: AppTextStyles.body),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.textOnDark,
              activeTrackColor: AppColors.accentOliveDark,
              inactiveThumbColor: AppColors.surfacePrimary,
              inactiveTrackColor: AppColors.surfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: <Widget>[
            _LeadingIcon(icon: icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Text(value!, style: AppTextStyles.caption),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color = danger ? AppColors.danger : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            child: Row(
              children: <Widget>[
                _LeadingIcon(
                  icon: icon,
                  color: enabled ? color : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: enabled ? color : AppColors.textMuted,
                    ),
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

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ?? AppColors.accentBrownDark;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.card,
      ),
      child: Icon(icon, color: resolvedColor, size: 20),
    );
  }
}
