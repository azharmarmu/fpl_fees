import 'package:flutter/material.dart';

/// Phone-first column: full bleed on small screens, centered max-width on wide.
class AppViewport extends StatelessWidget {
  const AppViewport({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) {
          return ColoredBox(
            color: const Color(0xFF0F1A12),
            child: child,
          );
        }
        return ColoredBox(
          color: const Color(0xFF07100A),
          child: Center(
            child: Container(
              width: maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A12),
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
