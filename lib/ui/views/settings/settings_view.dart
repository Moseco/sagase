import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:stacked/stacked.dart';

import 'settings_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SettingsViewModel>.reactive(
      viewModelBuilder: () => SettingsViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, __) => viewModel.handleBackButton(),
          child: HomeHeader(
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            child: SettingsList(
              lightTheme: const SettingsThemeData(
                settingsListBackground: Colors.transparent,
              ),
              darkTheme: const SettingsThemeData(
                settingsListBackground: Colors.transparent,
              ),
              sections: [
                if (kDebugMode)
                  SettingsSection(
                    title: const Text('Debug'),
                    tiles: [
                      SettingsTile.navigation(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Open dev screen'),
                        onPressed: (_) => viewModel.navigateToDev(),
                      ),
                    ],
                  ),
                SettingsSection(
                  title: const Text('General'),
                  tiles: [
                    SettingsTile.navigation(
                      title: const Text('Japanese font'),
                      onPressed: (_) => viewModel.setJapaneseFont(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('App theme'),
                      onPressed: (_) => viewModel.setAppTheme(),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.showPitchAccent,
                      onToggle: viewModel.setShowPitchAccent,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Show pitch accent'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.startOnLearningView,
                      onToggle: viewModel.setStartOnLearningView,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Start on learning screen'),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.properNounsEnabled,
                      onToggle: viewModel.setProperNounsEnabled,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Include proper nouns'),
                      description: const Text('Increases app size by ~100 MB.'),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('Flashcards'),
                  tiles: [
                    SettingsTile.switchTile(
                      initialValue: viewModel.flashcardLearningModeEnabled,
                      onToggle: viewModel.setFlashcardLearningModeEnabled,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Learning mode'),
                      description: const Text(
                        'Include a set amount of new flashcards alongside due flashcards. Long press a flashcard set to open it in a different mode.',
                      ),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.addNewFlashcardsInBatches,
                      onToggle: viewModel.setAddNewFlashcardsInBatches,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Add new flashcards in batches'),
                      description: const Text(
                        'When no due flashcards are available, add new flashcards in batches instead of all at once.',
                      ),
                    ),
                    SettingsTile.navigation(
                      enabled: viewModel.flashcardLearningModeEnabled ||
                          viewModel.addNewFlashcardsInBatches,
                      title: const Text('New flashcards per day'),
                      description: const Text(
                        'Number of new flashcards added when learning mode or batched adding is enabled.',
                      ),
                      onPressed: (_) => viewModel.setNewFlashcardsPerDay(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Initial spaced repetition interval'),
                      onPressed: (_) =>
                          viewModel.setInitialSpacedRepetitionInterval(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Flashcard distance'),
                      description: const Text(
                        'How far into the deck a flashcard is placed after a wrong answer, repeat answer, or while completing a new flashcard.',
                      ),
                      onPressed: (_) => viewModel.setFlashcardDistance(),
                    ),
                    SettingsTile.navigation(
                      title: const Text(
                          'Correct answers to complete a new flashcard'),
                      onPressed: (_) =>
                          viewModel.setFlashcardCorrectAnswersRequired(),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.showNewInterval,
                      onToggle: viewModel.setShowNewInterval,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title:
                          const Text('Preview new spaced repetition interval'),
                      description: const Text(
                        'Show the upcoming interval beneath the flashcard answer buttons.',
                      ),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.showDetailedProgress,
                      onToggle: viewModel.setShowDetailedProgress,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Show detailed progress'),
                      description: const Text(
                        'In learning mode, display due and new flashcards as separate numbers in the progress bar.',
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('App data'),
                  tiles: [
                    SettingsTile.switchTile(
                      initialValue: viewModel.analyticsEnabled,
                      onToggle: viewModel.setAnalyticsEnabled,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Analytics collection'),
                      description: const Text(
                        'Collect basic usage analytics. No personally identifying information is collected.',
                      ),
                    ),
                    SettingsTile.switchTile(
                      initialValue: viewModel.crashlyticsEnabled,
                      onToggle: viewModel.setCrashlyticsEnabled,
                      activeSwitchColor: Theme.of(context).colorScheme.primary,
                      title: const Text('Crash report collection'),
                      description: const Text(
                        'Collect crash reports to help with development. No personally identifying information is collected.',
                      ),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Delete analytics data'),
                      onPressed: (_) => viewModel.requestDataDeletion(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Delete search history'),
                      onPressed: (_) => viewModel.deleteSearchHistory(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Back up data'),
                      description: const Text(
                        'Export your lists, flashcard sets, and spaced repetition data to a file you can save.',
                      ),
                      onPressed: (_) => viewModel.backupData(),
                    ),
                    SettingsTile.navigation(
                      title: const Text('Restore from backup'),
                      description: const Text(
                        'Replaces all user data with the contents of the selected backup file.',
                      ),
                      onPressed: (_) => viewModel.restoreFromBackup(),
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text('About'),
                  tiles: [
                    SettingsTile.navigation(
                      leading: const Icon(Icons.link),
                      title: const Text('Submit feedback'),
                      onPressed: (_) => viewModel.openFeedback(),
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(Icons.history),
                      title: const Text('Changelog'),
                      onPressed: (_) => viewModel.openChangelog(),
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(Icons.policy),
                      title: const Text('Privacy policy'),
                      onPressed: (_) => viewModel.openPrivacyPolicy(),
                    ),
                    SettingsTile.navigation(
                      leading: const Icon(Icons.info),
                      title: const Text('About Sagase'),
                      onPressed: (_) => viewModel.navigateToAbout(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
