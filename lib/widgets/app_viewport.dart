import 'package:flutter/material.dart';

/// Keeps phone/tablet full-bleed; centers a readable column on wide laptops.
class AppViewport extends StatelessWidget {
  const AppViewport({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return ColoredBox(
          color: const Color(0xFF0F1A12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
