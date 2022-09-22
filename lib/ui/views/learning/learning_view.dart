import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';

import 'learning_viewmodel.dart';

class LearningView extends StatelessWidget {
  const LearningView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LearningViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<LearningViewModel>(),
      builder: (context, viewModel, child) => const Scaffold(
        body: HomeHeader(
          title: Text(
            'Learning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          child: Text('Learning'),
        ),
      ),
    );
  }
}
