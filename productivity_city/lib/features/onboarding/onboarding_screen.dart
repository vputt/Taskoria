import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:productivity_city/app/theme/app_colors.dart';
import 'package:productivity_city/app/theme/app_radius.dart';
import 'package:productivity_city/app/theme/app_text_styles.dart';
import 'package:productivity_city/shared/assets/asset_paths.dart';
import 'package:productivity_city/shared/providers/app_providers.dart';
import 'package:productivity_city/shared/widgets/pixel_image.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  static const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      title: 'Добро пожаловать\nв Taskoria',
      description: 'Превращай задачи в город,\nкоторый растет вместе с тобой.',
      backgroundAsset: AssetPaths.onboarding1,
      buttonLabel: 'Далее',
      isPrimaryLight: false,
    ),
    _OnboardingSlide(
      title: 'Задачи = прогресс',
      description: 'Каждое выполненное дело\nусиливает твой город.',
      backgroundAsset: AssetPaths.onboarding2,
      buttonLabel: 'Далее',
      isPrimaryLight: false,
    ),
    _OnboardingSlide(
      title: 'Развивай кварталы',
      description: 'Открывай здания, персонажей\nи новые точки роста.',
      backgroundAsset: AssetPaths.onboarding1,
      buttonLabel: 'Далее',
      isPrimaryLight: false,
    ),
    _OnboardingSlide(
      title: 'Начни сейчас!',
      description: 'Готов построить город мечты?',
      backgroundAsset: AssetPaths.onboarding2,
      buttonLabel: 'Создать аккаунт',
      isPrimaryLight: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding(String route) async {
    if (_isFinishing) {
      return;
    }

    setState(() => _isFinishing = true);
    try {
      await ref.read(sessionControllerProvider).markOnboardingSeen();
      if (!mounted) {
        return;
      }
      context.go(route);
    } finally {
      if (mounted) {
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (int index) {
          setState(() => _currentPage = index);
        },
        itemBuilder: (BuildContext context, int index) {
          final bool isLastPage = index == _slides.length - 1;
          return _OnboardingPage(
            slide: _slides[index],
            currentPage: _currentPage,
            pageCount: _slides.length,
            isFinishing: _isFinishing,
            onSkip: () => _finishOnboarding('/register'),
            onPrimaryPressed: () {
              if (isLastPage) {
                _finishOnboarding('/register');
                return;
              }
              _pageController.nextPage(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
              );
            },
            onSecondaryPressed: isLastPage
                ? () => _finishOnboarding('/login')
                : null,
          );
        },
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.slide,
    required this.currentPage,
    required this.pageCount,
    required this.onSkip,
    required this.onPrimaryPressed,
    required this.isFinishing,
    this.onSecondaryPressed,
  });

  final _OnboardingSlide slide;
  final int currentPage;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool isFinishing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PixelImage(slide.backgroundAsset, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.34),
              ],
              stops: const <double>[0, 0.58, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: isFinishing ? null : onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      textStyle: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Пропустить'),
                  ),
                ),
                const Spacer(flex: 3),
                const PixelImage(AssetPaths.cityEmblem, width: 126, height: 92),
                const SizedBox(height: 28),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display.copyWith(
                    fontSize: 28,
                    height: 1.16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 18,
                    height: 1.24,
                    color: Colors.white.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(flex: 4),
                _PageDots(currentPage: currentPage, pageCount: pageCount),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isFinishing ? null : onPrimaryPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: slide.isPrimaryLight
                          ? Colors.white
                          : const Color(0xFF8F898D),
                      foregroundColor: slide.isPrimaryLight
                          ? AppColors.accentBrownDark
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isFinishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            slide.buttonLabel,
                            style: AppTextStyles.button.copyWith(
                              fontSize: 18,
                              color: slide.isPrimaryLight
                                  ? AppColors.accentBrownDark
                                  : Colors.white,
                            ),
                          ),
                  ),
                ),
                if (onSecondaryPressed != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isFinishing ? null : onSecondaryPressed,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(
                      'Уже есть аккаунт? Войти',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(pageCount, (int index) {
        final bool selected = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 34 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.58),
            borderRadius: AppRadius.card,
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.backgroundAsset,
    required this.buttonLabel,
    required this.isPrimaryLight,
  });

  final String title;
  final String description;
  final String backgroundAsset;
  final String buttonLabel;
  final bool isPrimaryLight;
}
