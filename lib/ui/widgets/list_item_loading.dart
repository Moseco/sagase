import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListItemLoading extends StatelessWidget {
  final bool showLeading;

  const ListItemLoading({this.showLeading = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF4a4a4a) : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            if (showLeading)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 24,
                height: 24,
                color: Colors.white,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
