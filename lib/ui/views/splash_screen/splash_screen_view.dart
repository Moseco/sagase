import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'splash_screen_viewmodel.dart';

class SplashScreenView extends StatelessWidget {
  const SplashScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SplashScreenViewModel>.reactive(
      viewModelBuilder: () => SplashScreenViewModel(),
      fireOnViewModelReadyOnce: true,
      onViewModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        body: Center(
          child: Text(
            viewModel.getStatusText(),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
