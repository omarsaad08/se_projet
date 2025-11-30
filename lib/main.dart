import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

import 'package:se_project/appRouter.dart';
import 'package:se_project/helpers/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MainApp(appRouter: AppRouter()));
}

class MainApp extends StatelessWidget {
  final AppRouter appRouter;
  const MainApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return AppView(appRouter: appRouter);
  }
}

class AppView extends StatefulWidget {
  final AppRouter appRouter;
  const AppView({super.key, required this.appRouter});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      title: 'SE Project',
      theme: AppTheme.getDarkTheme(),
      onGenerateRoute: widget.appRouter.generateRoute,
      initialRoute: 'home',
    );
  }
}
