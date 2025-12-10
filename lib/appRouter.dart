import 'package:flutter/material.dart';
import 'package:se_project/presentation/screens/home.dart';
import 'package:se_project/presentation/screens/charts.dart';
import 'package:se_project/presentation/screens/pixel_wise.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case 'home':
        return MaterialPageRoute(builder: (_) => const Home());
      case 'charts':
        return MaterialPageRoute(builder: (_) => const Charts());
      case 'pixelWise':
        return MaterialPageRoute(builder: (_) => const PixelWiseMap());

      default:
        return MaterialPageRoute(builder: (_) => const Home());
    }
  }
}
