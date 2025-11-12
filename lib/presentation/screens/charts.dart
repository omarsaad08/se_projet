import 'package:flutter/material.dart';
import 'package:se_project/presentation/components/navbar.dart';

class Charts extends StatelessWidget {
  const Charts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(currentRoute: 'charts'),
      body: Column(),
    );
  }
}
