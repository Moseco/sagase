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
                viewModel.showCurrentChangelog ? 'Show full changelog' : 'Back',
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
            'What\'s new in 1.5',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.camera),
            title: Text('New and improved OCR'),
            subtitle: Text(
              'Find words in photos right from the search screen',
            ),
          ),
          ListTile(
            leading: Icon(Icons.playlist_add),
            title: Text('From text to flashcards'),
            subtitle: Text(
              'Bulk import vocab directly from text or images into your custom lists',
            ),
          ),
          ListTile(
            leading: Icon(Icons.school),
            title: Text('More flashcard options'),
            subtitle: Text(
              'Keep your studying on track with more options to manage new and due flashcards',
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
      child: Markdown(data: '''
# [1.5.1]
- Added undo and redo functionality to text analysis
- Added ability to open the keyboard on the search screen by tapping the search tab button
- Improved error handling during OCR
# [1.5.0]
- Full release of OCR with overhauled UI in the text analysis screen and ability to use OCR directly from the search screen
- Added ability to bulk import all identified vocab from text analysis into your custom lists
- Added option to space out flashcards if a large amount of due flashcards pile up
- Added option to restrict how many new flashcards are shown when no due flashcards are available
- Fixed performance issues during onboarding
# [1.4.2]
- Fixed disk space calculation during dictionary download
- Fixed crash effecting some users the first time they opened flashcards
# [1.4.1]
- Fixed text analysis processing of incomplete conjugations
- Fixed a bug with search when the query rapidly changed
- Fixed a bug that caused shared lists to be empty
# [1.4.0]
- Added 2k, 6k, 10k, and Kaishi 1.5k vocab lists
- Added wildcard searching (e.g., "*心")
- Added text analysis to search when no dictionary entries are found instead of just redirecting to text analysis
- Improved vocab search sorting
- Improved text analysis verb identification
- Improved text analysis handling of auxiliary verbs
- Fixed initial flashcard streak amount on reset
# [1.3.0]
- Added OCR beta to allow finding Japanese text in photos, a complete version should come in the next release
- Added user notes to vocab and kanji, these notes can also be shown in flashcards
- Improved text analysis dictionary lookup
- Stopped showing search only forms of vocab
- Fixed a bug that caused some search results to appear twice
- Fixed a bug that prevented some vocab from being displayed
- Fixed some typos
# [1.2.1]
- Updated flashcard performance graph UI
- Stopped creating unnecessary data when using random order flashcards
- Fixed issue that caused crashes when searching for special symbols
- Fixed rare issues with download status
# [1.2.0]
- Migrated from a custom database to SQLite reducing the install size by about half
- Added proper noun dictionary as an optional add-on
- Improved the text analysis UI and word detection 
- Added text analysis history
- Added flashcard performance reports that are shown when all due flashcards are finished
- Added recent flashcard performance to the flashcard set stats screen
- Added option to space out flashcards if a large amount of due flashcards pile up
- Changed "import from backup" to "restore from backup" which now deletes existing data before importing from the backup
- Added ability to scroll through lists from inside vocab and kanji screens
- Improved searching using special characters or those with accents
- Fixed various small UI bugs throughout the app
# [1.1.0]
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
