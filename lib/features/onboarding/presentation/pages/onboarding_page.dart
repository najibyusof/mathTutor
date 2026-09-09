import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/onboarding_step.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_dots.dart';

/// Three-slide introduction shown after the splash screen.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastStep => _index == OnboardingStep.steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastStep) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(AppStrings.onboardingSkip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: OnboardingStep.steps.length,
                  onPageChanged: (int index) => setState(() => _index = index),
                  itemBuilder: (BuildContext context, int index) =>
                      OnboardingSlide(step: OnboardingStep.steps[index]),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PageDots(
                count: OnboardingStep.steps.length,
                activeIndex: _index,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isLastStep
                    ? AppStrings.onboardingStart
                    : AppStrings.onboardingNext,
                onPressed: _next,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
