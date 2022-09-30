import 'package:sagase/ui/views/dev/dev_view.dart';
import 'package:sagase/ui/views/dictionary_lists/dictionary_lists_view.dart';
import 'package:sagase/ui/views/dictionary_lists/dictionary_lists_viewmodel.dart';
import 'package:sagase/ui/views/home/home_view.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase/ui/views/kanji_compounds/kanji_compounds_view.dart';
import 'package:sagase/ui/views/learning/learning_view.dart';
import 'package:sagase/ui/views/learning/learning_viewmodel.dart';
import 'package:sagase/ui/views/search/search_view.dart';
import 'package:sagase/ui/views/search/search_viewmodel.dart';
import 'package:sagase/ui/views/settings/settings_view.dart';
import 'package:sagase/ui/views/splash_screen/splash_screen_view.dart';
import 'package:sagase/ui/views/vocab/vocab_view.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@StackedApp(
  routes: [
    MaterialRoute(page: SplashScreenView, initial: true),
    CustomRoute(
      page: HomeView,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      children: [
        CustomRoute(page: SearchView),
        CustomRoute(page: DictionaryListsView),
        CustomRoute(page: LearningView),
        CustomRoute(page: SettingsView),
      ],
    ),
    MaterialRoute(page: VocabView),
    MaterialRoute(page: KanjiView),
    MaterialRoute(page: KanjiCompoundsView),
    MaterialRoute(page: DevView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    // IsarService is registered in SplashScreen to catch errors
    LazySingleton(classType: SearchViewModel),
    LazySingleton(classType: DictionaryListsViewModel),
    LazySingleton(classType: LearningViewModel),
  ],
)
class AppSetup {
  /** Serves no purpose besides having an annotation attached to it */
}
