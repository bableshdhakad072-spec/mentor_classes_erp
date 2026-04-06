import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Global footer on major screens.
class MentorFooter extends StatelessWidget {
  const MentorFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 2, color: AppTheme.deepBlue.withValues(alpha: 0.35)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            'Developed by Harshit Dhakad | Founder: Yogesh Udawat',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.deepBlue,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
