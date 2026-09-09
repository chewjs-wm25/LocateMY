import 'package:flutter/material.dart';
import 'package:locate_my/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/app/view_models/locale_view_model.dart';
import 'package:locate_my/app/view_models/navigation_view_model.dart';
import 'package:locate_my/modules/module_b/view_models/auth/auth_view_model.dart';
import 'package:locate_my/modules/module_a/view_models/home/home_view_model.dart';
import 'package:locate_my/modules/module_a/views/map/map_view.dart';
import 'package:locate_my/modules/module_a/views/home/home_screen.dart';
import 'package:locate_my/modules/module_b/views/auth/account_view.dart';
import 'package:locate_my/modules/module_b/views/auth/login_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  static const List<Widget> _widgetOptions = <Widget>[HomeScreen(), MapView()];

  void onItemTapped(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    Provider.of<NavigationViewModel>(context, listen: false).setIndex(index);
  }

  List<String> _getTitles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.titleHome, l10n.titleMap];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthViewModel>(context);
    if (!authProvider.isAuthenticated) {
      return const LoginView();
    }

    final l10n = AppLocalizations.of(context)!;
    final titles = _getTitles(context);
    final navProvider = Provider.of<NavigationViewModel>(context);
    final selectedIndex = navProvider.currentIndex;
    final showAppBar = selectedIndex != 1;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(titles[selectedIndex]),
              ),
              titleSpacing: 16,
              actions: [
                if (selectedIndex == 0)
                  Consumer<HomeViewModel>(
                    builder: (context, homeProvider, _) {
                      return IconButton(
                        icon: homeProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        onPressed: homeProvider.isLoading
                            ? null
                            : () async {
                                if (homeProvider.isRefreshLocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '请稍后再试，剩余 ${homeProvider.secondsUntilUnlock} 秒',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  await homeProvider.loadStats(force: true);
                                  if (homeProvider.error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(homeProvider.error!),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    homeProvider.clearError();
                                  }
                                }
                              },
                      );
                    },
                  ),
                PopupMenuButton<Locale>(
                  icon: const Icon(Icons.language_rounded),
                  tooltip: 'Change Language',
                  onSelected: (Locale locale) {
                    Provider.of<LocaleViewModel>(
                      context,
                      listen: false,
                    ).setLocale(locale);
                  },
                  itemBuilder: (BuildContext context) {
                    return LocaleViewModel.supportedLocales.map((
                      Map<String, dynamic> item,
                    ) {
                      final Locale locale = item['locale'];
                      final String name = item['name'];
                      final isSelected =
                          Provider.of<LocaleViewModel>(
                            context,
                            listen: false,
                          ).locale ==
                          locale;

                      return PopupMenuItem<Locale>(
                        value: locale,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.account_circle_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountView(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
            )
          : null,
      body: IndexedStack(index: selectedIndex, children: _widgetOptions),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map),
              label: l10n.navMap,
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: AppColors.primaryBase,
          unselectedItemColor: AppColors.textMutedLight,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            height: 1.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
            height: 1.2,
          ),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
        ),
      ),
    );
  }
}
