import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/ui/views/splash_screen/splash_screen_viewmodel.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('SplashScreenViewModelTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    test('Initial install - success', () async {
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(
        open: DictionaryStatus.initialInstall,
        importDatabase: ImportResult.success,
      );
      getAndRegisterMecabService(initialize: false, extractFiles: true);
      getAndRegisterDownloadService(
        hasSufficientFreeSpace: true,
        downloadRequiredAssets: true,
      );
      getAndRegisterDigitalInkService(initialize: true);

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      verify(navigationService.navigateToOnboardingView()).called(1);
      verify(navigationService.replaceWith(any)).called(1);
    });

    test('Initial install - insufficient free space', () async {
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(open: DictionaryStatus.initialInstall);
      getAndRegisterMecabService(initialize: false);
      getAndRegisterDownloadService(hasSufficientFreeSpace: false);

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      expect(viewModel.status, SplashScreenStatus.downloadFreeSpaceError);
      verify(navigationService.navigateToOnboardingView()).called(1);
      verifyNever(navigationService.replaceWith(any));
    });

    test('Initial install - download failed', () async {
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(open: DictionaryStatus.initialInstall);
      getAndRegisterMecabService(initialize: false);
      getAndRegisterDownloadService(
        hasSufficientFreeSpace: true,
        downloadRequiredAssets: false,
      );

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      expect(viewModel.status, SplashScreenStatus.downloadError);
      verify(navigationService.navigateToOnboardingView()).called(1);
      verifyNever(navigationService.replaceWith(any));

      // Try again and failed
      await viewModel.startDownload();

      expect(viewModel.status, SplashScreenStatus.downloadError);
      verifyNever(navigationService.replaceWith(any));
    });

    test('Dictionary out of date', () async {
      getAndRegisterSharedPreferencesService(getOnboardingFinished: true);
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(
        open: DictionaryStatus.outOfDate,
        importDatabase: ImportResult.success,
      );
      getAndRegisterMecabService(initialize: true);
      getAndRegisterDownloadService(
        hasSufficientFreeSpace: true,
        downloadDictionary: true,
      );
      getAndRegisterDigitalInkService(initialize: true);

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      expect(viewModel.status, SplashScreenStatus.downloadRequest);
      verifyNever(navigationService.navigateToOnboardingView());
      verifyNever(navigationService.replaceWith(any));

      // Start download
      await viewModel.startDownload();

      verify(navigationService.replaceWith(any)).called(1);
    });

    test('Migration required', () async {
      getAndRegisterSharedPreferencesService(getOnboardingFinished: true);
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(
        open: DictionaryStatus.migrationRequired,
        importDatabase: ImportResult.success,
      );
      getAndRegisterMecabService(initialize: true);
      getAndRegisterDownloadService(
        hasSufficientFreeSpace: true,
        downloadDictionary: true,
      );
      getAndRegisterDigitalInkService(initialize: true);

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      expect(viewModel.status, SplashScreenStatus.downloadRequest);
      verifyNever(navigationService.navigateToOnboardingView());
      verifyNever(navigationService.replaceWith(any));

      // Start download
      await viewModel.startDownload();

      verify(navigationService.replaceWith(any)).called(1);
    });

    test('Previous transfer interrupted', () async {
      getAndRegisterSharedPreferencesService(getOnboardingFinished: true);
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDictionaryService(
        open: DictionaryStatus.transferInterrupted,
        importDatabase: ImportResult.success,
      );
      getAndRegisterMecabService(initialize: true);
      getAndRegisterDownloadService(
        hasSufficientFreeSpace: true,
        downloadDictionary: true,
      );
      getAndRegisterDigitalInkService(initialize: true);

      final viewModel = SplashScreenViewModel();
      await viewModel.futureToRun();

      expect(viewModel.status, SplashScreenStatus.downloadRequest);
      verifyNever(navigationService.navigateToOnboardingView());
      verifyNever(navigationService.replaceWith(any));

      // Start download
      await viewModel.startDownload();

      verify(navigationService.replaceWith(any)).called(1);
    });
  });
}
