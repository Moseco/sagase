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
                title: const Text('About Sagase'),
                tiles: [
                  SettingsTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App version 0.2.0'),
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
