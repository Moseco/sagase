import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/ui/themes.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_themes/stacked_themes.dart';

import 'app/app.bottomsheets.dart';
import 'app/app.dialogs.dart';
import 'app/app.locator.dart';
import 'app/app.router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  await ThemeManager.initialise();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool useJapaneseSerifFont =
        locator<SharedPreferencesService>().getUseJapaneseSerifFont();
    return ThemeBuilder(
      lightTheme: getLightTheme(useJapaneseSerifFont),
      darkTheme: getDarkTheme(useJapaneseSerifFont),
      builder: (context, regularTheme, darkTheme, themeMode) => MaterialApp(
        title: 'Sagase',
        theme: regularTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        navigatorKey: StackedService.navigatorKey,
        onGenerateRoute: StackedRouter().onGenerateRoute,
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
      ),
    );
  }
}
