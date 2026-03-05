import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Заполни email и пароль.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(sessionControllerProvider)
          .login(email: email, password: password);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Не удалось выполнить вход. Попробуй еще раз.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 18),
                  const Center(
                    child: PixelImage(
                      AssetPaths.cityEmblem,
                      width: 118,
                      height: 88,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'С возвращением!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(
                        fontSize: 24,
                        color: const Color(0xFF1E120D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Продолжай строить свой город.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        color: const Color(0xFFBBB3AF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const _AuthLabel(label: 'Email'),
                  const SizedBox(height: 10),
                  _AuthInput(
                    controller: _emailController,
                    hintText: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 20),
                  const _AuthLabel(label: 'Пароль'),
                  const SizedBox(height: 10),
                  _AuthInput(
                    controller: _passwordController,
                    hintText: '********',
                    obscureText: _obscurePassword,
                    enabled: !_isSubmitting,
                    trailing: IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFB6ACA7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            _showMessage(
                              'Восстановление пароля добавим следующим шагом.',
                            );
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.accentBrownDark,
                    ),
                    child: Text(
                      'Забыли пароль?',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Войти',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go('/register'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentBrownDark,
                      ),
                      child: Text(
                        'Нет аккаунта? Зарегистрируйтесь',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLabel extends StatelessWidget {
  const _AuthLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.body.copyWith(
        fontSize: 16,
        color: const Color(0xFF3B2517),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AuthInput extends StatelessWidget {
  const _AuthInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: AppTextStyles.body.copyWith(
        fontSize: 16,
        color: const Color(0xFF3B2517),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
          fontSize: 16,
          color: const Color(0xFFC9C1BC),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.pageBackground,
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: Color(0xFFA88B66), width: 0.9),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: Color(0xFFA16437), width: 1.2),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: Color(0xFFD6CCC7), width: 0.9),
        ),
      ),
    );
  }
}
