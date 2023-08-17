import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, FlutterError;
import 'package:sagase/firebase_options.dart';
import 'package:stacked/stacked_annotations.dart';

class FirebaseService implements InitializableDependency {
  bool get crashlyticsEnabled =>
      FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled;

  @override
  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // If in debug mode disable analytics and crashlytics collection
    if (kDebugMode) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  }

  void setAnalyticsEnabled(bool enabled) {
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
  }

  void setCrashlyticsEnabled(bool enabled) {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  }
}
