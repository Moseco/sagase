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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: IntroductionScreen(
          next: const Text('Next'),
          done: const Text('Done'),
          onDone: viewModel.finishOnboarding,
          dotsDecorator: const DotsDecorator(
            color: Colors.grey,
            activeColor: Colors.deepPurple,
          ),
          pages: [
            PageViewModel(
              image: const Text('探', style: TextStyle(fontSize: 80)),
              title: 'Sagase',
              body:
                  'Welcome to Sagase, a Japanese-English dictionary and learning tool.',
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
                  'Master the language with learning optimized flashcards using the built in lists, such as JLPT and Jouyou, or create your own.',
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
