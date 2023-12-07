import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:stacked/stacked.dart';

import 'onboarding_viewmodel.dart';

class OnboardingView extends StackedView<OnboardingViewModel> {
  const OnboardingView({super.key});

  @override
  OnboardingViewModel viewModelBuilder(context) => OnboardingViewModel();

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
          pages: [
            PageViewModel(
              image: const Text('探', style: TextStyle(fontSize: 80)),
              title: 'Sagase',
              body:
                  'Welcome to Sagase, a Japanese-English dictionary and learning app.',
            ),
            PageViewModel(
              image: const Text('辞書', style: TextStyle(fontSize: 80)),
              title: 'Dictionary',
              body:
                  'Intuitively search using romaji, kana, and kanji. Don\'t worry about not knowing how to type a character, simply sketch it out and let the hand writing recognition do the rest.',
            ),
            PageViewModel(
              image: const Text('練習', style: TextStyle(fontSize: 80)),
              title: 'Practice',
              body:
                  'Master the language with learning optimized flashcards using the built in lists, such as JLPT and Kanji Kentei, or create your own.',
            ),
            PageViewModel(
              image: const Text('設定', style: TextStyle(fontSize: 80)),
              title: 'Settings',
              bodyWidget: Column(
                children: [
                  const Text(
                    'This app can collect basic usage analytics and crash reports. No personally identifying information is collected. You can always update your choice in the settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  TextButton(
                    onPressed: viewModel.openPrivacyPolicy,
                    child: const Text(
                      'View privacy policy',
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
            ),
          ],
        ),
      ),
    );
  }
}
