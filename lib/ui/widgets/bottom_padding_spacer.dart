import 'package:flutter/material.dart';

class BottomPaddingSpacer extends StatelessWidget {
  const BottomPaddingSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.paddingOf(context).bottom);
  }
}
