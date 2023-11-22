import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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
            SplashScreenStatus.downloadingAssets => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Downloading dictionary',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CircularPercentIndicator(
                    radius: 40,
                    lineWidth: 8,
                    animation: true,
                    animateFromLastPercent: true,
                    percent: viewModel.downloadStatus,
                    center: Text(
                      "${(viewModel.downloadStatus * 100).toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: Colors.deepPurple,
                  ),
                ],
              ),
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
            SplashScreenStatus.downloadError => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Failed to download the dictionary.\nMake sure you are connected to the internet and try again.\nIf it keeps happening try updating the app.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: viewModel.startDownload,
                    child: const Text('Retry download'),
                  ),
                ],
              ),
            SplashScreenStatus.databaseError => const Text(
                'Something went wrong with the dictionary.\nPlease try closing the app and reopening it.',
                textAlign: TextAlign.center,
              ),
            SplashScreenStatus.downloadRequest => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'There is a dictionary upgrade available.\nPlease keep the app open during the upgrade; it should take less then a minute.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: viewModel.startDownload,
                    child: const Text('Start download'),
                  ),
                ],
              ),
            SplashScreenStatus.dictionaryUpgradeError => const Text(
                'Something went wrong while upgrading the dictionary.\nPlease try closing the app and reopening it.',
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
