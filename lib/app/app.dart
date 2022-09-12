import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/views/dev/dev_view.dart';
import 'package:sagase/ui/views/home/home_view.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase/ui/views/vocab/vocab_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@StackedApp(
  routes: [
    MaterialRoute(page: HomeView, initial: true),
    MaterialRoute(page: VocabView),
    MaterialRoute(page: KanjiView),
    MaterialRoute(page: DevView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    Presolve(
      classType: IsarService,
      presolveUsing: IsarService.initialize,
    ),
  ],
)
class AppSetup {
  /** Serves no purpose besides having an annotation attached to it */
}
