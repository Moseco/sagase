import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'dev_viewmodel.dart';

class DevView extends StatelessWidget {
  const DevView({Key? key}) : super(key: key);

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
                        onPressed: viewModel.createDatabase,
                        child: const Text('Create database'),
                      ),
                      ElevatedButton(
                        onPressed: viewModel.exportDatabase,
                        child: const Text('Export database'),
                      ),
                      ElevatedButton(
                        onPressed: viewModel.importDatabase,
                        child: const Text('Import database'),
                      ),
                      ElevatedButton(
                        onPressed: viewModel.runPerformanceTest,
                        child: const Text('Run performance test'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
