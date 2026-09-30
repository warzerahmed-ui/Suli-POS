import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';

/// لۆگۆی براندی RAND SUITE بە دیزاینێکی مۆدێرن و تایبەت بۆ خاڵی فرۆشتن.
class RandSuiteLogo extends StatelessWidget {
  const RandSuiteLogo({
    super.key,
    this.size = 36,
    this.showTagline = false,
    this.isCompact = false,
    this.brightness,
  });

  final double size;
  final bool showTagline;
  final bool isCompact;
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = (brightness ?? theme.brightness) == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final Widget badgeIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'SP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.44,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          badgeIcon,
          const SizedBox(width: 8),
          Text(
            'SULI-POS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: size * 0.48,
              color: textColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        badgeIcon,
        const SizedBox(height: 10),
        Text(
          'SULI-POS',
          style: TextStyle(
            fontSize: size * 0.68,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: textColor,
          ),
        ),
        if (showTagline) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            AppStrings.brandTagline,
            style: TextStyle(
              fontSize: 12,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// نیشاندەری سەرچاوەی گەشەپێدەر "Powered by RAND SUITE".
class PoweredByRandSuite extends StatelessWidget {
  const PoweredByRandSuite({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final Color textColor = light ? Colors.white70 : Colors.black54;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          AppStrings.poweredBy,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
