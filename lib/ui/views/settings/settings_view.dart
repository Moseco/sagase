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
        body: HomeHeader(
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
                    title: const Text('Set Japanese font'),
                    onPressed: (_) => viewModel.setJapaneseFont(),
                  ),
                  SettingsTile.navigation(
                    title: const Text('Set app theme'),
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
                    description: const Text('Increases app size by ~100mb'),
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
                      'If enabled, a set amount of new flashcards will be included with due flashcards. You can also long press a flashcard set to open in a different mode.',
                    ),
                  ),
                  SettingsTile.navigation(
                    enabled: viewModel.flashcardLearningModeEnabled,
                    title: const Text('Set new flashcards per day'),
                    description: const Text(
                      'The amount of new flashcards to be added along with due cards while in learning mode.',
                    ),
                    onPressed: (_) => viewModel.setNewFlashcardsPerDay(),
                  ),
                  SettingsTile.navigation(
                    title: const Text('Set initial spaced repetition interval'),
                    onPressed: (_) =>
                        viewModel.setInitialSpacedRepetitionInterval(),
                  ),
                  SettingsTile.navigation(
                    title: const Text('Set flashcard distance'),
                    description: const Text(
                      'How far into the stack a flashcard is put after a wrong answer, repeat answer, or while completing a new flashcard.',
                    ),
                    onPressed: (_) => viewModel.setFlashcardDistance(),
                  ),
                  SettingsTile.navigation(
                    title: const Text(
                        'Set correct answers required to complete a new flashcard'),
                    onPressed: (_) =>
                        viewModel.setFlashcardCorrectAnswersRequired(),
                  ),
                  SettingsTile.switchTile(
                    initialValue: viewModel.showNewInterval,
                    onToggle: viewModel.setShowNewInterval,
                    activeSwitchColor: Theme.of(context).colorScheme.primary,
                    title: const Text('Preview new spaced repetition interval'),
                    description: const Text(
                      'Shown underneath flashcard answer buttons.',
                    ),
                  ),
                  SettingsTile.switchTile(
                    initialValue: viewModel.showDetailedProgress,
                    onToggle: viewModel.setShowDetailedProgress,
                    activeSwitchColor: Theme.of(context).colorScheme.primary,
                    title: const Text('Show detailed progress'),
                    description: const Text(
                      'If enabled and in learning mode, the progress bar will display due flashcards and new flashcards as separate numbers instead of as one number.',
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
                      'If enabled, the app collects basic usage analytics. No personally identifying information is collected.',
                    ),
                  ),
                  SettingsTile.switchTile(
                    initialValue: viewModel.crashlyticsEnabled,
                    onToggle: viewModel.setCrashlyticsEnabled,
                    activeSwitchColor: Theme.of(context).colorScheme.primary,
                    title: const Text('Crash report collection'),
                    description: const Text(
                      'If enabled, the app collects crash report information to help with development. No personally identifying information is collected.',
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
                    title: const Text('Backup data'),
                    description: const Text(
                      'Exports user created lists, flashcard sets, and spaced repetition data. The created file can then be saved in a safe place.',
                    ),
                    onPressed: (_) => viewModel.backupData(),
                  ),
                  SettingsTile.navigation(
                    title: const Text('Restore from backup'),
                    description: const Text(
                      'This will delete all user data and then import new user data from the selected backup file.',
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
                    title: const Text('Open changelog'),
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
    );
  }
}
