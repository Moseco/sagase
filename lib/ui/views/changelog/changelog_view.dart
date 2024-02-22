import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
              child: viewModel.showCurrentChangelog
                  ? const _CurrentChangelog()
                  : const _ChangelogHistory(),
            ),
            TextButton(
              onPressed: viewModel.toggleShowCurrentChangelog,
              child: Text(
                viewModel.showCurrentChangelog ? 'Show history' : 'Back',
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
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
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
            title: Text('Share lists'),
            subtitle: Text(
              'Export your lists and share them with other Sagase users',
            ),
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('Flashcard improvements'),
            subtitle: Text('See more detailed progress information'),
          ),
          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Bug fixes'),
            subtitle: Text(
              'Improvements to landscape mode, flashcards UI, visual consistency, and more',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogHistory extends StatelessWidget {
  const _ChangelogHistory();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Markdown(data: '''# [1.1.0]
- Updated how backups are handled. Backup files created before version 1.1 will not work anymore. Contact the developer if you need to recover an old backup
- Added ability to export and import user generated lists
- Added option to show more detailed progress information during learning mode flashcards
- Updated flashcard deck UI to behave more naturally
- Added option to view flashcard interval totals as a percentage
- Changed how initial spaced repetition intervals are calculated
- Updated UI to prevent system UI from covering important app elements
- Updated text selection to be consistent for vocab, kanji, and radical screens
- Improved cache management
- Improved visual consistency of buttons
- Fixed a bug that caused flashcard progress UI to become out of sync
- Fixed a bug that caused honorifics to be skipped during text analysis
- Fixed a bug that caused Japanese keyboards to sometimes not work correctly
- Added this changelog
# [1.0.0] - Initial release'''),
    );
  }
}
