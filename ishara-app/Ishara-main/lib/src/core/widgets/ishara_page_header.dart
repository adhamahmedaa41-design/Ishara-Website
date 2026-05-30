import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/ishara_theme.dart';

/// Unified page header used across Talk, Vision, Safety, and Learn screens.
///
/// Layout:
///   [vertical accent bar] [title + subtitle]   [icon badge]
///
/// The accent bar color, icon, and background tint are all customisable so
/// each screen keeps its own identity while sharing the same structure.
class IsharaPageHeader extends StatelessWidget {
  const IsharaPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.teal,
    required this.orange,
    required this.isDark,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color teal;
  final Color orange;
  final bool isDark;

  /// Optional extra widget placed after the icon badge (e.g. a reset button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0, top + 10, 16, 14),
          decoration: BoxDecoration(
            color: isDark
                ? IsharaColors.darkCard.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? IsharaColors.darkBorder
                    : IsharaColors.lightBorder,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left accent bar ───────────────────────────────────────
              Container(
                width: 4,
                height: 48,
                margin: const EdgeInsets.only(right: 14, left: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teal, orange],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // ── Title + subtitle ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) => LinearGradient(
                        colors: [teal, orange],
                      ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Icon badge ────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      teal.withValues(alpha: 0.18),
                      orange.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: teal.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: teal, size: 22),
              ),

              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.06, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
