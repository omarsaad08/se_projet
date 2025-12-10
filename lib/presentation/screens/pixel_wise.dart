import 'package:flutter/material.dart';
import 'package:se_project/presentation/components/navbar.dart';
import 'package:se_project/presentation/screens/pixel_wise_page.dart';

class PixelWiseMap extends StatelessWidget {
  const PixelWiseMap({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: NavBar(currentRoute: 'pixelWise'),
      body: PixelWisePage(),
    );
  }
}
