import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'dev_viewmodel.dart';

class DevView extends StatelessWidget {
  const DevView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DevViewModel>.reactive(
      viewModelBuilder: () => DevViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: const Text('Dev View')),
        body: SafeArea(
          child: viewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: viewModel.importDatabase,
                        child: const Text('Import database'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
