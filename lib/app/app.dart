import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/ui/bottom_sheets/assign_lists_bottom_sheet.dart';
import 'package:sagase/ui/bottom_sheets/assign_my_lists_bottom_sheet.dart';
import 'package:sagase/ui/dialogs/text_field_dialog.dart';
import 'package:sagase/ui/views/dev/dev_view.dart';
import 'package:sagase/ui/views/dictionary_list/dictionary_list_view.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_view.dart';
import 'package:sagase/ui/views/flashcard_sets/flashcard_sets_view.dart';
import 'package:sagase/ui/views/flashcards/flashcards_view.dart';
import 'package:sagase/ui/views/home/home_viewmodel.dart';
import 'package:sagase/ui/views/lists/lists_view.dart';
import 'package:sagase/ui/views/lists/lists_viewmodel.dart';
import 'package:sagase/ui/views/home/home_view.dart';
import 'package:sagase/ui/views/kana/kana_view.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase/ui/views/kanji_compounds/kanji_compounds_view.dart';
import 'package:sagase/ui/views/kanji_radicals/kanji_radicals_view.dart';
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
        CustomRoute(page: ListsView),
        CustomRoute(page: LearningView),
        CustomRoute(page: SettingsView),
      ],
    ),
    MaterialRoute(page: VocabView),
    MaterialRoute(page: KanjiView),
    MaterialRoute(page: KanjiCompoundsView),
    MaterialRoute(page: DictionaryListView),
    MaterialRoute(page: KanjiRadicalsView),
    MaterialRoute(page: KanaView),
    MaterialRoute(page: FlashcardSetsView),
    MaterialRoute(page: FlashcardSetInfoView),
    MaterialRoute(page: FlashcardsView),
    MaterialRoute(page: DevView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: SnackbarService),
    Presolve(
      classType: DigitalInkService,
      presolveUsing: DigitalInkService.initialize,
    ),
    // IsarService is registered in SplashScreen to catch errors
    LazySingleton(classType: HomeViewModel),
    LazySingleton(classType: SearchViewModel),
    LazySingleton(classType: ListsViewModel),
    LazySingleton(classType: LearningViewModel),
  ],
  bottomsheets: [
    StackedBottomsheet(classType: AssignMyListsBottomSheet),
    StackedBottomsheet(classType: AssignListsBottomSheet),
  ],
  dialogs: [
    StackedDialog(classType: TextFieldDialog),
  ],
)
class AppSetup {
  /** Serves no purpose besides having an annotation attached to it */
}
