import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'changelog_viewmodel.dart';

class ChangelogView extends StackedView<ChangelogViewModel> {
  const ChangelogView({super.key});

  @override
  ChangelogViewModel viewModelBuilder(context) => ChangelogViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: viewModel.showCurrentChangelog
                    ? const _CurrentChangelog()
                    : const _ChangelogHistory(),
              ),
            ),
            TextButton(
              onPressed: viewModel.toggleShowCurrentChangelog,
              child: Text(
                viewModel.showCurrentChangelog
                    ? 'Show history'
                    : 'Show current',
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: viewModel.closeChangelog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentChangelog extends StatelessWidget {
  const _CurrentChangelog();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 10),
        Text(
          '探せの知らせ',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'What\'s new',
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.share),
          title: Text('Feature'),
          subtitle: Text('Feature details'),
        ),
        ListTile(
          leading: Icon(Icons.bug_report),
          title: Text('Bug fixes'),
          subtitle: Text('Bug fix details'),
        ),
      ],
    );
  }
}

class _ChangelogHistory extends StatelessWidget {
  const _ChangelogHistory();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            '[1.0.0] - Initial release',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }
}
