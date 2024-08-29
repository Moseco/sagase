import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:stacked/stacked.dart';

import 'onboarding_viewmodel.dart';

class OnboardingView extends StackedView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  OnboardingViewModel viewModelBuilder(context) => OnboardingViewModel();

  static const _pageDecoration = PageDecoration(
    pageMargin: EdgeInsets.zero,
    imageFlex: 7,
    bodyFlex: 8,
  );

  @override
  Widget builder(context, viewModel, child) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IntroductionScreen(
          next: const Text('Next'),
          done: const Text('Done'),
          showSkipButton: true,
          skip: const Text('Skip'),
          onDone: viewModel.finishOnboarding,
          onSkip: viewModel.finishOnboarding,
          dotsDecorator: DotsDecorator(
            color: Colors.grey,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          safeAreaList: const [true, true, false, false],
          pages: [
            PageViewModel(
              image: const Text('探', style: TextStyle(fontSize: 80)),
              title: 'Sagase',
              body:
                  'Welcome to Sagase, a Japanese-English dictionary and learning app.',
              decoration: _pageDecoration,
            ),
            PageViewModel(
              image: const Text('辞書', style: TextStyle(fontSize: 80)),
              title: 'Dictionary',
              body:
                  'Intuitively search using romaji, kana, and kanji. Don\'t worry about not knowing how to type a character, simply sketch it out and let the hand writing recognition do the rest.',
              decoration: _pageDecoration,
            ),
            PageViewModel(
              image: const Text('練習', style: TextStyle(fontSize: 80)),
              title: 'Practice',
              body:
                  'Master the language with learning optimized flashcards using the built in lists, such as JLPT and Kanji Kentei, or create your own.',
              decoration: _pageDecoration,
            ),
            PageViewModel(
              image: const Text('設定', style: TextStyle(fontSize: 80)),
              title: 'Settings',
              decoration: _pageDecoration,
              bodyWidget: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Include proper nouns',
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: const Text('Increases app size by ~100mb'),
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: viewModel.properNounsEnabled,
                    onChanged: viewModel.setProperNounsEnabled,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Analytics',
                      style: TextStyle(fontSize: 18),
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: viewModel.analyticsEnabled,
                    onChanged: viewModel.setAnalyticsEnabled,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Crash reports',
                      style: TextStyle(fontSize: 18),
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: viewModel.crashlyticsEnabled,
                    onChanged: viewModel.setCrashlyticsEnabled,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This app can collect basic usage analytics and crash reports. No personally identifying information is collected. You can always update your choice in the settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  TextButton(
                    onPressed: viewModel.openPrivacyPolicy,
                    child: const Text(
                      'Open privacy policy',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            PageViewModel(
              image: const Text('頑張って', style: TextStyle(fontSize: 80)),
              title: 'Let\'s get started',
              body: 'Good luck with your Japanese learning journey!',
              decoration: _pageDecoration,
            ),
          ],
        ),
      ),
    );
  }
}
