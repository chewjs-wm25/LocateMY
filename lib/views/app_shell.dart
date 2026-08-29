import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/locale_provider.dart';
import '../providers/navigation_provider.dart';
import 'map/map_view.dart';
import 'home/home_screen.dart';
import 'account/account_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MapView(),
  ];

  List<String> _getTitles(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.titleHome,
      l10n.titleMap,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = _getTitles(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navProvider.currentIndex;
    final showAppBar = selectedIndex != 1;

    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(titles[selectedIndex]),
        ),
        titleSpacing: 16,
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Change Language',
            onSelected: (Locale locale) {
              Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
            },
            itemBuilder: (BuildContext context) {
              return LocaleProvider.supportedLocales.map((Map<String, dynamic> item) {
                final Locale locale = item['locale'];
                final String name = item['name'];
                final isSelected = Provider.of<LocaleProvider>(context, listen: false).locale == locale;
                
                return PopupMenuItem<Locale>(
                  value: locale,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
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
                MaterialPageRoute(builder: (context) => const AccountView()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ) : null,
      body: _widgetOptions.elementAt(selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderLight,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: l10n.navHome),
            BottomNavigationBarItem(icon: const Icon(Icons.map_rounded), label: l10n.navMap),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: AppColors.primaryBase,
          unselectedItemColor: AppColors.textMutedLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, height: 1.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, height: 1.2),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          onTap: (index) => navProvider.setIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
        ),
      ),
    );
  }
}
