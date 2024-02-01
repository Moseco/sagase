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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: switch (viewModel.status) {
              SplashScreenStatus.waiting => Container(),
              SplashScreenStatus.downloadingAssets => _Body(
                  title: 'Downloading Assets',
                  widget: CircularPercentIndicator(
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
                ),
              SplashScreenStatus.upgradingDictionary => const _Body(
                  title: 'Upgrading Dictionary',
                  subtitle: 'This should be pretty quick.',
                  widget: CircularProgressIndicator(),
                ),
              SplashScreenStatus.downloadError => _Body(
                  title: 'Download Failed',
                  subtitle:
                      'Make sure you are connected to the internet and try again.\nIf it keeps happening try updating the app.',
                  widget: ElevatedButton(
                    onPressed: viewModel.startDownload,
                    child: const Text('Retry download'),
                  ),
                ),
              SplashScreenStatus.databaseError => const _Body(
                  title: 'Dictionary Error',
                  subtitle:
                      'Something went wrong with the dictionary.\nPlease try closing the app and reopening it.',
                ),
              SplashScreenStatus.downloadRequest => _Body(
                  title: 'Upgrade Available',
                  subtitle:
                      'There is a new version of the dictionary available.\nPlease keep the app open during the upgrade.\nIt should take less then a minute.',
                  widget: ElevatedButton(
                    onPressed: viewModel.startDownload,
                    child: const Text('Start download'),
                  ),
                ),
              SplashScreenStatus.dictionaryUpgradeError => const _Body(
                  title: 'Upgrade Failed',
                  subtitle:
                      'Something went wrong while upgrading the dictionary.\nPlease try closing the app and reopening it.',
                ),
              SplashScreenStatus.downloadFreeSpaceError => const _Body(
                  title: 'Download Failed',
                  subtitle: 'Not enough free space to set up the dictionary.',
                ),
              _ => _Body(
                  title: 'Finishing Setup',
                  subtitle:
                      'Completed ${viewModel.status.index - SplashScreenStatus.importingDictionary.index}/3',
                  widget: const CircularProgressIndicator(),
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? widget;

  const _Body({
    required this.title,
    this.subtitle,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
            ),
          ),
        if (widget != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: widget,
          ),
      ],
    );
  }
}
