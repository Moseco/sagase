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
                title: const Text('Flashcards'),
                tiles: [
                  SettingsTile.navigation(
                    title: const Text('Initial spaced repetition interval'),
                    onPressed: (_) =>
                        viewModel.setInitialSpacedRepetitionInterval(),
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
                    title: const Text('New flashcards per day'),
                    trailing: Text(viewModel.newFlashcardsPerDay.toString()),
                    description: const Text(
                      'The amount of new flashcards to be added along with due cards while in learning mode.',
                    ),
                    onPressed: (_) => viewModel.setNewFlashcardsPerDay(),
                  ),
                ],
              ),
              SettingsSection(
                title: const Text('About Sagase'),
                tiles: [
                  SettingsTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App version 0.4.0'),
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
