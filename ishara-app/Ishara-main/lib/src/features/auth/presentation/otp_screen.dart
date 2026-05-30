import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';
import 'login_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _len = 6;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());

  bool _loading = false;
  bool _resendLoading = false;
  String? _error;
  int _shakeKey = 0;
  int _cooldownSec = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  // ── OTP verification ────────────────────────────────────────────────────────

  void _shake() => setState(() => _shakeKey++);
  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _len - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (_otp.length == _len) _verify();
  }

  Future<void> _verify() async {
    if (_otp.length < _len) {
      setState(() => _error = t(ref).allDigits);
      _shake();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    final result = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.email, _otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      context.go(AppRoute.profilePhotoSetup);
    } else {
      setState(() => _error = result.message);
      _shake();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _resend() async {
    if (_cooldownSec > 0 || _resendLoading) return;
    setState(() {
      _resendLoading = true;
      _error = null;
    });
    HapticFeedback.selectionClick();

    final result = await ref
        .read(authProvider.notifier)
        .resendOtp(widget.email);

    if (!mounted) return;
    setState(() => _resendLoading = false);

    if (result.success) {
      _startCooldown();
    } else {
      setState(() => _error = result.message);
    }
  }

  void _startCooldown() {
    setState(() => _cooldownSec = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldownSec--;
        if (_cooldownSec <= 0) t.cancel();
      });
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

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
      body: Stack(children: [
        const IsharaAuroraBackground(intensity: 0.8),
        SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Hero icon with double glow ──────────────────────────
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      teal.withValues(alpha: 0.28),
                      teal.withValues(alpha: 0.0),
                    ]),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 1.0,
                      end: 1.1,
                      duration: 2200.ms,
                      curve: Curves.easeInOut,
                    ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [teal, orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.4),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: IsharaMotion.slow,
                      curve: IsharaMotion.overshoot,
                    )
                    .fadeIn(duration: IsharaMotion.base),
              ]),

              const SizedBox(height: 28),

              Text(
                'VERIFY · YOUR · EMAIL',
                style: TextStyle(
                  color: teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ).animate().fadeIn(
                    delay: 100.ms,
                    duration: IsharaMotion.base,
                  ),

              const SizedBox(height: 10),

              Text(
                s.verifyEmail,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: -0.6,
                ),
              ).animate().fadeIn(
                    delay: 150.ms,
                    duration: IsharaMotion.base,
                  ),

              const SizedBox(height: 8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                  children: [
                    TextSpan(text: '${s.otpSent}\n'),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),

              const SizedBox(height: 24),

              // ── 6 OTP boxes ───────────────────────────────────────────────
              Builder(
                builder: (_) {
                  final boxes = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _len,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        isDark: isDark,
                        teal: teal,
                        onChanged: (v) => _onDigitChanged(i, v),
                      ),
                    ),
                  );
                  if (_shakeKey == 0) return boxes;
                  return boxes
                      .animate(key: ValueKey(_shakeKey))
                      .shakeX(amount: 8, duration: 400.ms, hz: 5);
                },
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

              if (_error != null) ...[
                const SizedBox(height: 14),
                AuthErrorBanner(message: _error!, isDark: isDark),
              ],

              const SizedBox(height: 32),

              GradientAuthButton(
                label: s.verify,
                loading: _loading,
                isDark: isDark,
                onTap: _verify,
              ).animate().fadeIn(delay: 330.ms, duration: 400.ms),

              const SizedBox(height: 20),

              SizedBox(
                height: IsharaColors.minTouchTarget,
                child: TextButton(
                  onPressed:
                      (_cooldownSec > 0 || _resendLoading) ? null : _resend,
                  child:
                      _resendLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: teal,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            _cooldownSec > 0
                                ? '${s.resendIn} ${_cooldownSec}s'
                                : s.resendCode,
                            style: TextStyle(
                              color:
                                  _cooldownSec > 0
                                      ? (isDark
                                          ? IsharaColors.mutedDark
                                          : IsharaColors.mutedLight)
                                      : teal,
                              fontWeight: FontWeight.w600,
                              decoration:
                                  _cooldownSec > 0
                                      ? null
                                      : TextDecoration.underline,
                            ),
                          ),
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      ]),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.teal,
    required this.onChanged,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final Color teal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        onChanged: onChanged,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(
              color:
                  isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(
              color:
                  isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: IsharaColors.cardRadius,
            borderSide: BorderSide(color: teal, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
