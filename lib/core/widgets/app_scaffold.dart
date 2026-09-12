import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/location.dart';

class LocateMyScaffold extends StatelessWidget {
  const LocateMyScaffold({
    required this.state,
    required this.title,
    required this.body,
    this.up = true,
    this.onBack,
    this.nav = false,
    this.actions,
    this.fab,
    this.bottomBar,
    super.key,
  });

  final LocateMyState state;
  final String title;
  final Widget body;
  final bool up;
  final VoidCallback? onBack;
  final bool nav;
  final List<Widget>? actions;
  final Widget? fab;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: up
          ? IconButton(
              onPressed: onBack ?? state.back,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      actions: actions,
    ),
    body: SafeArea(child: body),
    floatingActionButton: fab,
    bottomNavigationBar:
        bottomBar ?? (nav ? _NavigationBar(state: state) : null),
  );
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({required this.state});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) {
    final index = state.page == PageId.home
        ? 0
        : state.page == PageId.map
        ? 1
        : 2;
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) {
        if (value == 0) state.home();
        if (value == 1) state.map();
        if (value == 2) state.go(PageId.account, keepBack: false);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: '地图',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '账户',
        ),
      ],
    );
  }
}
