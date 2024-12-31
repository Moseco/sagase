import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/download_service.dart';
import 'package:sagase/services/firebase_service.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/ui/bottom_sheets/assign_lists_bottom_sheet.dart';
import 'package:sagase/ui/bottom_sheets/assign_my_lists_bottom_sheet.dart';
import 'package:sagase/ui/bottom_sheets/select_dictionary_item_bottom_sheet.dart';
import 'package:sagase/ui/bottom_sheets/stroke_order_bottom_sheet.dart';
import 'package:sagase/ui/dialogs/confirmation_dialog.dart';
import 'package:sagase/ui/dialogs/flashcard_set_report_dialog.dart';
import 'package:sagase/ui/dialogs/flashcard_start_dialog.dart';
import 'package:sagase/ui/dialogs/font_selection_dialog.dart';
import 'package:sagase/ui/dialogs/info_dialog.dart';
import 'package:sagase/ui/dialogs/initial_interval_dialog.dart';
import 'package:sagase/ui/dialogs/number_text_field_dialog.dart';
import 'package:sagase/ui/dialogs/percent_indicator_dialog.dart';
import 'package:sagase/ui/dialogs/progress_indicator_dialog.dart';
import 'package:sagase/ui/dialogs/search_filter_dialog.dart';
import 'package:sagase/ui/dialogs/text_field_dialog.dart';
import 'package:sagase/ui/dialogs/theme_selection_dialog.dart';
import 'package:sagase/ui/views/about/about_view.dart';
import 'package:sagase/ui/views/changelog/changelog_view.dart';
import 'package:sagase/ui/views/dev/dev_view.dart';
import 'package:sagase/ui/views/dictionary_list/dictionary_list_view.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_view.dart';
import 'package:sagase/ui/views/flashcard_set_settings/flashcard_set_settings_view.dart';
import 'package:sagase/ui/views/flashcards/flashcards_view.dart';
import 'package:sagase/ui/views/home/home_viewmodel.dart';
import 'package:sagase/ui/views/kanji_list/kanji_list_view.dart';
import 'package:sagase/ui/views/ocr/ocr_view.dart';
import 'package:sagase/ui/views/proper_noun/proper_noun_view.dart';
import 'package:sagase/ui/views/radical/radical_view.dart';
import 'package:sagase/ui/views/lists/lists_view.dart';
import 'package:sagase/ui/views/home/home_view.dart';
import 'package:sagase/ui/views/kana/kana_view.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase/ui/views/kanji_compounds/kanji_compounds_view.dart';
import 'package:sagase/ui/views/radicals/radicals_view.dart';
import 'package:sagase/ui/views/learning/learning_view.dart';
import 'package:sagase/ui/views/onboarding/onboarding_view.dart';
import 'package:sagase/ui/views/search/search_view.dart';
import 'package:sagase/ui/views/search/search_viewmodel.dart';
import 'package:sagase/ui/views/settings/settings_view.dart';
import 'package:sagase/ui/views/splash_screen/splash_screen_view.dart';
import 'package:sagase/ui/views/text_analysis/text_analysis_view.dart';
import 'package:sagase/ui/views/vocab/vocab_view.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_themes/stacked_themes.dart';

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
    MaterialRoute(page: RadicalsView),
    MaterialRoute(page: RadicalView),
    MaterialRoute(page: KanjiListView),
    MaterialRoute(page: KanaView),
    MaterialRoute(page: FlashcardSetSettingsView),
    MaterialRoute(page: FlashcardSetInfoView),
    MaterialRoute(page: FlashcardsView),
    MaterialRoute(page: TextAnalysisView),
    MaterialRoute(page: OnboardingView),
    MaterialRoute(page: AboutView),
    CustomRoute(
      page: ChangelogView,
      transitionsBuilder: TransitionsBuilders.slideBottom,
    ),
    MaterialRoute(page: ProperNounView),
    MaterialRoute(page: OcrView),
    MaterialRoute(page: DevView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: SnackbarService),
    InitializableSingleton(classType: FirebaseService),
    InitializableSingleton(classType: SharedPreferencesService),
    LazySingleton(classType: DictionaryService),
    LazySingleton(classType: DigitalInkService),
    LazySingleton(classType: MecabService),
    LazySingleton(
      classType: ThemeService,
      resolveUsing: ThemeService.getInstance,
    ),
    LazySingleton(classType: DownloadService),
    LazySingleton(classType: HomeViewModel),
    LazySingleton(classType: SearchViewModel),
  ],
  bottomsheets: [
    StackedBottomsheet(classType: AssignMyListsBottomSheet),
    StackedBottomsheet(classType: AssignListsBottomSheet),
    StackedBottomsheet(classType: StrokeOrderBottomSheet),
    StackedBottomsheet(classType: DictionaryItemsBottomSheet),
  ],
  dialogs: [
    StackedDialog(classType: TextFieldDialog),
    StackedDialog(classType: FlashcardSetReportDialog),
    StackedDialog(classType: InitialIntervalDialog),
    StackedDialog(classType: FlashcardStartDialog),
    StackedDialog(classType: NumberTextFieldDialog),
    StackedDialog(classType: ConfirmationDialog),
    StackedDialog(classType: ProgressIndicatorDialog),
    StackedDialog(classType: FontSelectionDialog),
    StackedDialog(classType: SearchFilterDialog),
    StackedDialog(classType: ThemeSelectionDialog),
    StackedDialog(classType: InfoDialog),
    StackedDialog(classType: PercentIndicatorDialog),
  ],
)
class AppSetup {
  /** Serves no purpose besides having an annotation attached to it */
}
