import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show nestedNavigationKey;

import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => locator<HomeViewModel>(),
      builder: (context, viewModel, child) => WillPopScope(
        onWillPop: () async {
          return viewModel.handleBackButton();
        },
        child: Scaffold(
          body: ExtendedNavigator(
            navigatorKey:
                StackedService.nestedNavigationKey(nestedNavigationKey),
            initialRoute: HomeViewRoutes.searchView,
            router: HomeViewRouter(),
            observers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
          ),
          bottomNavigationBar: viewModel.showNavigationBar
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: GNav(
                      haptic: false,
                      gap: 8,
                      color: Theme.of(context).iconTheme.color,
                      activeColor: Colors.white,
                      iconSize: 24,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      tabBorderRadius: 15,
                      tabBackgroundColor: Colors.deepPurple,
                      selectedIndex: viewModel.currentIndex,
                      onTabChange: viewModel.handleNavigation,
                      tabs: const [
                        GButton(
                          icon: Icons.search,
                          text: 'Search',
                        ),
                        GButton(
                          icon: Icons.format_list_bulleted,
                          text: 'Lists',
                        ),
                        GButton(
                          icon: Icons.school,
                          text: 'Learning',
                        ),
                        GButton(
                          icon: Icons.settings,
                          text: 'Settings',
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
