import 'package:flutter/material.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/theme/app_theme.dart';
import 'package:locatemy/features/account/presentation/account_pages.dart';
import 'package:locatemy/features/analysis/presentation/analysis_page.dart';
import 'package:locatemy/features/explore/presentation/explore_page.dart';
import 'package:locatemy/features/home/presentation/home_page.dart';
import 'package:locatemy/features/property/presentation/property_pages.dart';

export 'core/models/location.dart';
export 'core/models/property.dart';

void main() => runApp(const LocateMyApp());

class LocateMyApp extends StatefulWidget {
  const LocateMyApp({super.key});

  @override
  State<LocateMyApp> createState() => _LocateMyAppState();
}

class _LocateMyAppState extends State<LocateMyApp> {
  late final LocateMyState state;

  @override
  void initState() {
    super.initState();
    state = LocateMyState();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LocateMY 原型',
    debugShowCheckedModeBanner: false,
    theme: locateMyTheme(),
    home: AnimatedBuilder(
      animation: state,
      builder: (context, _) => _LocateMyRouter(state: state),
    ),
  );
}

class _LocateMyRouter extends StatelessWidget {
  const _LocateMyRouter({required this.state});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => switch (state.page) {
    PageId.home => HomePage(state: state),
    PageId.map => ExplorePage(state: state),
    PageId.analysis => AnalysisPage(state: state),
    PageId.cost => CostPage(state: state),
    PageId.safety ||
    PageId.social ||
    PageId.infra ||
    PageId.amenities ||
    PageId.transport => AnalysisDetailPage(state: state, page: state.page),
    PageId.saved => SavedPage(state: state),
    PageId.properties => PropertyArchivePage(state: state),
    PageId.addProperty => PropertyEditorPage(state: state),
    PageId.detail => PropertyDetailPage(state: state),
    PageId.compare => PropertyComparePage(state: state),
    PageId.report => ReportPage(state: state),
    PageId.reports => ReportsPage(state: state),
    PageId.account => AccountPage(state: state),
    PageId.login => LoginPage(state: state),
    PageId.register => RegisterPage(state: state),
  };
}
