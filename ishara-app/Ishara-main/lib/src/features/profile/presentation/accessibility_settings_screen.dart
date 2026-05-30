import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/accessibility_settings.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = ref.watch(accessibilityProvider);
    final ctrl = ref.read(accessibilityProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.6),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              children: [
                IsharaHero(
                  eyebrow: 'Accessibility',
                  title: 'Make Ishara yours',
                  description:
                      'Tune visual contrast and text size. Every toggle has an immediate, visible effect.',
                  icon: Icons.accessibility_new_rounded,
                ),

                // ── Visual ──────────────────────────────────────
                const IsharaSectionLabel(
                  'Visual',
                  icon: Icons.visibility_rounded,
                ),
                IsharaSurface(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ToggleRow(
                        icon: Icons.contrast_rounded,
                        label: 'High contrast',
                        subtitle:
                            'WCAG AAA borders + stronger semantic colors',
                        value: s.highContrast,
                        onChanged: (v) =>
                            ctrl.update(s.copyWith(highContrast: v)),
                      ),
                      _Divider(isDark: isDark),
                      _PaletteRow(
                        current: s.colorBlindMode,
                        onChange: (v) =>
                            ctrl.update(s.copyWith(colorBlindMode: v)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: IsharaSpacing.sectionGap),

                // ── Reading ─────────────────────────────────────
                const IsharaSectionLabel(
                  'Reading',
                  icon: Icons.menu_book_rounded,
                ),
                IsharaSurface(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Text scale',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IsharaStatusPill(
                            label: '${(s.textScale * 100).round()}%',
                            tone: IsharaStatusTone.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 14 + (s.textScale - 1) * 18,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Slider(
                        value: s.textScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: '${(s.textScale * 100).round()}%',
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          ctrl.update(s.copyWith(textScale: v));
                        },
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: teal.withValues(alpha: value ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: isDark
            ? IsharaColors.darkBorder
            : IsharaColors.lightBorder,
      );
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.current, required this.onChange});
  final ColorBlindMode current;
  final ValueChanged<ColorBlindMode> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    final options = const [
      (ColorBlindMode.none, 'Default', 'Standard Ishara palette'),
      (ColorBlindMode.deuter, 'Deuteranopia', 'Adjusted red-green'),
      (ColorBlindMode.protan, 'Protanopia', 'Adjusted red-green'),
      (ColorBlindMode.tritan, 'Tritanopia', 'Adjusted blue-yellow'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette_rounded, color: teal, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Color-blind palette',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final (mode, label, sub) = o;
              final selected = current == mode;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChange(mode);
                },
                child: AnimatedContainer(
                  duration: IsharaMotion.fast,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? teal.withValues(alpha: 0.18)
                        : (isDark
                            ? IsharaColors.darkCard
                            : IsharaColors.lightCard),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? teal
                          : (isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder),
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? teal
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
