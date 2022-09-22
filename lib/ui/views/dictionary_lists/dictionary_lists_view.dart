import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';

import 'dictionary_lists_viewmodel.dart';

class DictionaryListsView extends StatelessWidget {
  const DictionaryListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DictionaryListsViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<DictionaryListsViewModel>(),
      builder: (context, viewModel, child) => const Scaffold(
        body: HomeHeader(
          title: Text(
            'Lists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          child: Text('Lists'),
        ),
      ),
    );
  }
}
