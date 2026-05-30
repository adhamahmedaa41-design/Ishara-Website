/// Ishara — bold & expressive design-system primitives.
///
/// Components live here so every screen pulls from one source. Each
/// primitive composes the existing IsharaColors / IsharaSpacing /
/// IsharaMotion tokens; never hard-code colours or durations in screens.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/ishara_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IsharaHero — bold page hero with display-weight title, eyebrow label,
// description, optional trailing action. Replaces the older
// IsharaPageHeader for new screens.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaHero extends StatelessWidget {
  const IsharaHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.icon,
    this.trailing,
    this.gradient = true,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? trailing;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final foreground =
        isDark ? IsharaColors.darkForeground : IsharaColors.lightForeground;

    // Single-line page header: [icon badge] [title], with an optional
    // subtitle/description underneath. The old uppercase "eyebrow" row was
    // removed because it duplicated the title text in caps right above it.
    return Padding(
      padding: IsharaSpacing.heroPad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: gradient
                              ? LinearGradient(colors: [teal, orange])
                              : null,
                          color: gradient ? null : teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: gradient ? Colors.white : teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(
                      duration: IsharaMotion.slow,
                      delay: 60.ms,
                    ),
                // Subtitle/description line removed — every screen now shows
                // just the icon + title in the hero. Callers still pass a
                // `description` but it's intentionally ignored.
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IsharaSurface — the canonical card. Replaces the bespoke glassmorphism
// containers scattered across screens. Three variants:
//   • plain  — standard background card
//   • accent — light teal-tinted background, used for primary content
//   • dark   — full dark surface inverted from theme (e.g. camera card)
// ─────────────────────────────────────────────────────────────────────────────

enum IsharaSurfaceVariant { plain, accent, dark }

class IsharaSurface extends StatelessWidget {
  const IsharaSurface({
    super.key,
    required this.child,
    this.variant = IsharaSurfaceVariant.plain,
    this.padding = const EdgeInsets.all(20),
    this.glow = false,
    this.onTap,
  });

  final Widget child;
  final IsharaSurfaceVariant variant;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    late final Color bg;
    late final Color borderColor;
    switch (variant) {
      case IsharaSurfaceVariant.plain:
        bg = isDark ? IsharaColors.darkCard : IsharaColors.lightCard;
        borderColor = isDark
            ? IsharaColors.darkBorder
            : IsharaColors.lightBorder;
        break;
      case IsharaSurfaceVariant.accent:
        bg = teal.withValues(alpha: isDark ? 0.14 : 0.08);
        borderColor = teal.withValues(alpha: 0.3);
        break;
      case IsharaSurfaceVariant.dark:
        bg = const Color(0xFF0A0F1A);
        borderColor = Colors.white.withValues(alpha: 0.08);
        break;
    }

    final container = AnimatedContainer(
      duration: IsharaMotion.base,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: IsharaColors.surfaceRadius,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: IsharaColors.elevatedShadow(dark: isDark, glow: glow),
      ),
      child: child,
    );

    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      borderRadius: IsharaColors.surfaceRadius,
      child: InkWell(
        borderRadius: IsharaColors.surfaceRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: container,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IsharaMetric — large numeric display for hero data (currency total,
// SOS countdown, lesson streak, FPS readout). Splits the value and the
// unit so the unit can hang at a smaller weight.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaMetric extends StatelessWidget {
  const IsharaMetric({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.icon,
    this.color,
    this.size = IsharaMetricSize.large,
  });

  final String value;
  final String? unit;
  final String? label;
  final IconData? icon;
  final Color? color;
  final IsharaMetricSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = color ??
        (isDark ? IsharaColors.tealDark : IsharaColors.tealLight);
    final foreground =
        isDark ? IsharaColors.darkForeground : IsharaColors.lightForeground;

    final valueSize = switch (size) {
      IsharaMetricSize.small => 32.0,
      IsharaMetricSize.medium => 48.0,
      IsharaMetricSize.large => 64.0,
      IsharaMetricSize.giant => 92.0,
    };
    final unitSize = valueSize * 0.34;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                label!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    accent,
                    isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight,
                  ],
                ).createShader(rect),
                child: Text(
                  value,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: valueSize,
                    height: 1.0,
                    letterSpacing: -2.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 6),
              Padding(
                padding: EdgeInsets.only(bottom: valueSize * 0.08),
                child: Text(
                  unit!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.55),
                    fontSize: unitSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

enum IsharaMetricSize { small, medium, large, giant }

// ─────────────────────────────────────────────────────────────────────────────
// IsharaActionTile — primary CTA. A high-contrast pill that fills the
// width, with optional leading icon and trailing arrow. Used for "Start
// camera", "Translate", "Arm SOS" style entry points.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaActionTile extends StatelessWidget {
  const IsharaActionTile({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.onTap,
    this.variant = IsharaActionVariant.gradient,
    this.loading = false,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final IsharaActionVariant variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final disabled = onTap == null || loading;

    final bg = switch (variant) {
      IsharaActionVariant.gradient => null,
      IsharaActionVariant.outline =>
        (isDark ? IsharaColors.darkCard : IsharaColors.lightCard),
      IsharaActionVariant.danger => const Color(0xFFDC2626),
    };

    final gradient = switch (variant) {
      IsharaActionVariant.gradient =>
        isharaHorizontalGradient(dark: isDark),
      _ => null,
    };

    final fg = switch (variant) {
      IsharaActionVariant.outline => teal,
      _ => Colors.white,
    };

    final iconBg = switch (variant) {
      IsharaActionVariant.outline => teal.withValues(alpha: 0.12),
      _ => Colors.white.withValues(alpha: 0.22),
    };

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: disabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          height: subtitle == null ? 64 : 78,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: disabled ? null : gradient,
            color: disabled
                ? (isDark ? IsharaColors.darkCard : IsharaColors.lightCard)
                : bg,
            borderRadius: BorderRadius.circular(20),
            border: variant == IsharaActionVariant.outline
                ? Border.all(color: teal.withValues(alpha: 0.55), width: 2)
                : null,
            boxShadow: disabled || variant == IsharaActionVariant.outline
                ? null
                : [
                    BoxShadow(
                      color: (variant == IsharaActionVariant.danger
                              ? const Color(0xFFDC2626)
                              : teal)
                          .withValues(alpha: 0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: loading
                      ? Padding(
                          padding: const EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            color: fg,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Icon(icon, color: fg, size: 20),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: disabled
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                            : fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: disabled
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4)
                              : fg.withValues(alpha: 0.78),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: disabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.35)
                      : fg.withValues(alpha: 0.92),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum IsharaActionVariant { gradient, outline, danger }

// ─────────────────────────────────────────────────────────────────────────────
// IsharaStatusPill — compact pill for live status indicators. Optional
// leading pulse dot animates softly so the user sees "things are alive".
// ─────────────────────────────────────────────────────────────────────────────

class IsharaStatusPill extends StatelessWidget {
  const IsharaStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.tone = IsharaStatusTone.neutral,
    this.pulse = false,
  });

  final String label;
  final IconData? icon;
  final IsharaStatusTone tone;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    late final Color color;
    switch (tone) {
      case IsharaStatusTone.good:
        color = const Color(0xFF22C55E);
        break;
      case IsharaStatusTone.warn:
        color = const Color(0xFFF59E0B);
        break;
      case IsharaStatusTone.danger:
        color = const Color(0xFFDC2626);
        break;
      case IsharaStatusTone.accent:
        color = teal;
        break;
      case IsharaStatusTone.neutral:
        color = isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight;
        break;
    }

    Widget dot = Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (pulse) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 700.ms)
          .then()
          .fadeOut(duration: 700.ms);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
          ] else ...[
            dot,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

enum IsharaStatusTone { neutral, accent, good, warn, danger }

// ─────────────────────────────────────────────────────────────────────────────
// IsharaSegmented — pill segmented control. Replaces ad-hoc tab toggles.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaSegmentedItem<T> {
  const IsharaSegmentedItem({
    required this.value,
    required this.label,
    this.icon,
  });
  final T value;
  final String label;
  final IconData? icon;
}

class IsharaSegmented<T> extends StatelessWidget {
  const IsharaSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<IsharaSegmentedItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark
            ? IsharaColors.darkCard
            : IsharaColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: _SegBtn<T>(
                item: it,
                selected: selected == it.value,
                onTap: () => onChanged(it.value),
                teal: teal,
              ),
            ),
        ],
      ),
    );
  }
}

class _SegBtn<T> extends StatelessWidget {
  const _SegBtn({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.teal,
  });
  final IsharaSegmentedItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: IsharaMotion.fast,
        curve: IsharaMotion.standard,
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [
                  teal,
                  theme.brightness == Brightness.dark
                      ? IsharaColors.orangeDark
                      : IsharaColors.orangeLight,
                ])
              : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 16,
                color: selected ? Colors.white : teal,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              item.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? Colors.white : teal,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IsharaBentoTile — bento-grid tile for dashboard-like screens. Holds a
// title, hero metric/icon, and optional CTA. Variants for size.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaBentoTile extends StatelessWidget {
  const IsharaBentoTile({
    super.key,
    required this.title,
    this.value,
    this.icon,
    this.subtitle,
    this.tone = IsharaBentoTone.plain,
    this.onTap,
    this.height = 130,
  });

  final String title;
  final String? value;
  final String? subtitle;
  final IconData? icon;
  final IsharaBentoTone tone;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    late final Decoration decoration;
    late final Color fg;
    late final Color accentFg;
    switch (tone) {
      case IsharaBentoTone.plain:
        decoration = BoxDecoration(
          color: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
          borderRadius: IsharaColors.surfaceRadius,
          border: Border.all(
            color: isDark
                ? IsharaColors.darkBorder
                : IsharaColors.lightBorder,
          ),
          boxShadow: IsharaColors.elevatedShadow(dark: isDark),
        );
        fg = isDark
            ? IsharaColors.darkForeground
            : IsharaColors.lightForeground;
        accentFg = teal;
        break;
      case IsharaBentoTone.gradient:
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [teal, orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: IsharaColors.surfaceRadius,
          boxShadow: [
            BoxShadow(
              color: teal.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -4,
            ),
          ],
        );
        fg = Colors.white;
        accentFg = Colors.white.withValues(alpha: 0.86);
        break;
      case IsharaBentoTone.dark:
        decoration = BoxDecoration(
          color: const Color(0xFF0A0F1A),
          borderRadius: IsharaColors.surfaceRadius,
          boxShadow: IsharaColors.elevatedShadow(dark: true),
        );
        fg = Colors.white;
        accentFg = teal;
        break;
    }

    final content = Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tone == IsharaBentoTone.gradient
                        ? Colors.white.withValues(alpha: 0.18)
                        : accentFg.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentFg, size: 16),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentFg,
                    letterSpacing: 1.4,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (value != null)
            Text(
              value!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.displaySmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                fontSize: 30,
                height: 1.0,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: IsharaColors.surfaceRadius,
      child: InkWell(
        borderRadius: IsharaColors.surfaceRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: content,
      ),
    );
  }
}

enum IsharaBentoTone { plain, gradient, dark }

// ─────────────────────────────────────────────────────────────────────────────
// IsharaGlowBlob — decorative floating accent blob. Used behind hero
// elements to give the bold direction its expressive backdrop.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaGlowBlob extends StatelessWidget {
  const IsharaGlowBlob({
    super.key,
    this.size = 280,
    this.color,
    this.opacity = 0.36,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ??
        (isDark ? IsharaColors.tealDark : IsharaColors.tealLight);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              c.withValues(alpha: opacity),
              c.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IsharaSectionLabel — small uppercase label used above content sections.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaSectionLabel extends StatelessWidget {
  const IsharaSectionLabel(this.label, {super.key, this.trailing, this.icon});
  final String label;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: teal),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: teal,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IsharaAuroraBackground — soft gradient + drifting blobs behind a hero.
// Used on landing tabs so the page never feels flat.
// ─────────────────────────────────────────────────────────────────────────────

class IsharaAuroraBackground extends StatelessWidget {
  const IsharaAuroraBackground({
    super.key,
    this.intensity = 1.0,
  });
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final purple = IsharaColors.purple;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: IsharaGlowBlob(
                size: 360,
                color: teal,
                opacity: 0.28 * intensity,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: -8,
                    end: 8,
                    duration: 4400.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
            Positioned(
              top: 80,
              left: -100,
              child: IsharaGlowBlob(
                size: 320,
                color: orange,
                opacity: 0.22 * intensity,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 6,
                    end: -6,
                    duration: 5200.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
            Positioned(
              top: math.max(220, 240.0),
              right: -60,
              child: IsharaGlowBlob(
                size: 240,
                color: purple,
                opacity: 0.18 * intensity,
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(
                    begin: -4,
                    end: 4,
                    duration: 6000.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
