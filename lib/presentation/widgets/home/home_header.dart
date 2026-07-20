import "package:flutter/material.dart";
import "package:tempo/config/theme/app_theme.dart";

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tu Equilibrio Digital.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Toma conciencia de cómo usas tu tiempo y encuentra el balance perfecto para tu día a día.",
              style: TextStyle(color: AppTheme.textSegundary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
