import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'splash_screen_viewmodel.dart';

class SplashScreenView extends StackedView<SplashScreenViewModel> {
  const SplashScreenView({super.key});

  @override
  SplashScreenViewModel viewModelBuilder(context) => SplashScreenViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: switch (viewModel.status) {
            SplashScreenStatus.waiting => Container(),
            SplashScreenStatus.upgradingDictionary => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Upgrading dictionary. Please wait.\nThis should take less than 30 seconds.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CircularProgressIndicator(),
                ],
              ),
            SplashScreenStatus.databaseError => const Text(
                'Something went wrong with the dictionary.\nPlease try closing the app and reopening it.',
                textAlign: TextAlign.center,
              ),
            _ => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Preparing the dictionary. Please wait.\nThis should take less than 30 seconds.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Completed ${viewModel.status.index - SplashScreenStatus.importingDictionary.index}/3',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const CircularProgressIndicator(),
                ],
              ),
          },
        ),
      ),
    );
  }
}
