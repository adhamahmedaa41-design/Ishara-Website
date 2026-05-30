import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isLoggedIn) {
      context.go(AppRoute.home);
    } else {
      context.go(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050911) : const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 1.4),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo with double glow halo ───────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            teal.withValues(alpha: 0.35),
                            teal.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1.0,
                          end: 1.12,
                          duration: 2200.ms,
                          curve: Curves.easeInOut,
                        ),
                    Container(
                      width: 156,
                      height: 156,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [teal, orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.45),
                            blurRadius: 60,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: orange.withValues(alpha: 0.28),
                            blurRadius: 90,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipOval(
                        child: Container(
                          color: isDark
                              ? const Color(0xFF0A0F1A)
                              : Colors.white,
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/images/ishara_app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                          duration: IsharaMotion.slow,
                          curve: IsharaMotion.overshoot,
                        )
                        .fadeIn(duration: IsharaMotion.slow),
                  ],
                ),

                const SizedBox(height: 38),

                // ── Eyebrow ────────────────────────────────────────────
                Text(
                  'ACCESSIBILITY · COMPANION',
                  style: TextStyle(
                    color: teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                  ),
                ).animate().fadeIn(
                      delay: 200.ms,
                      duration: IsharaMotion.base,
                    ),
                const SizedBox(height: 12),

                // ── Display name with gradient shader ──────────────────
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => LinearGradient(
                    colors: [teal, orange],
                  ).createShader(
                    Rect.fromLTWH(0, 0, b.width, b.height),
                  ),
                  child: Text(
                    s.ishara,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.2,
                      height: 1.0,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: 320.ms,
                      duration: IsharaMotion.slow,
                    )
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 320.ms,
                      duration: IsharaMotion.slow,
                      curve: IsharaMotion.emphasized,
                    ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    s.eslCompanion,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                      letterSpacing: 0.4,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(
                      delay: 540.ms,
                      duration: IsharaMotion.base,
                    ),

                const SizedBox(height: 56),

                // ── Indeterminate loading bar ─────────────────────────
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: teal.withValues(alpha: 0.14),
                      valueColor: AlwaysStoppedAnimation<Color>(teal),
                    ),
                  ),
                ).animate().fadeIn(
                      delay: 800.ms,
                      duration: IsharaMotion.base,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
