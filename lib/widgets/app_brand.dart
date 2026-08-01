import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config.dart';

/// Compact brand row: logo + app name, optional current date on the right.
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    this.logoSize = 40,
    this.showName = true,
    this.showDate = true,
  });

  final double logoSize;
  final bool showName;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEE, d MMM yyyy').format(DateTime.now());
    return Row(
      children: [
        Image.asset(
          kAppLogoAsset,
          width: logoSize,
          height: logoSize,
          filterQuality: FilterQuality.high,
        ),
        if (showName) ...[
          const SizedBox(width: 10),
          Text(
            kAppName,
            style: GoogleFonts.bebasNeue(
              fontSize: logoSize * 0.85,
              color: const Color(0xFFB8F27A),
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
        ],
        if (showDate) ...[
          const Spacer(),
          Text(
            today,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
