import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHARED auth widgets — exported for Register & OTP screens.
// All four (IsharaAuthLogo / AuthField / GradientAuthButton / AuthErrorBanner /
// AuthFieldsShaker) keep their public names so existing imports keep working.
// ─────────────────────────────────────────────────────────────────────────────

/// Bold auth-screen logo — large gradient ring + display-weight wordmark.
class IsharaAuthLogo extends ConsumerWidget {
  const IsharaAuthLogo({
    super.key,
    required this.teal,
    required this.orange,
    required this.theme,
    this.compact = false,
  });
  final Color teal, orange;
  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoSize = compact ? 76.0 : 116.0;
    final ringSize = compact ? 110.0 : 168.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: ringSize,
              height: ringSize,
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
                  end: 1.08,
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    LinearGradient(colors: [teal, orange]),
                boxShadow: [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.4),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/ishara_app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 14 : 22),
        Text(
          'ACCESSIBILITY · COMPANION',
          style: TextStyle(
            color: teal,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => LinearGradient(colors: [teal, orange])
              .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
          child: Text(
            t(ref).ishara,
            style: TextStyle(
              fontSize: compact ? 36 : 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
              fontFamily: theme.textTheme.displayLarge?.fontFamily,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthFieldsShaker extends StatelessWidget {
  const AuthFieldsShaker({
    super.key,
    required this.shakeKey,
    required this.child,
  });
  final int shakeKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakeKey == 0) return child;
    return child
        .animate(key: ValueKey(shakeKey))
        .shakeX(amount: 6, duration: 400.ms, hz: 4);
  }
}

/// Bold input field with focus glow + animated border.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.teal,
    required this.validator,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool isDark, obscure;
  final Color teal;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.teal;
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: IsharaMotion.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: teal.withValues(alpha: 0.32),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        validator: widget.validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color:
              isDark ? IsharaColors.darkForeground : IsharaColors.lightForeground,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: (isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight)
                .withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: teal.withValues(alpha: _focused ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: teal),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark
                  ? IsharaColors.darkBorder
                  : IsharaColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark
                  ? IsharaColors.darkBorder
                  : IsharaColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

/// Bold primary button — wraps IsharaActionTile so existing call sites
/// (Register, OTP, ProfilePhotoSetup) keep working without refactoring.
class GradientAuthButton extends StatelessWidget {
  const GradientAuthButton({
    super.key,
    required this.label,
    required this.loading,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final bool loading, isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IsharaActionTile(
      label: label,
      icon: Icons.arrow_forward_rounded,
      trailingIcon: null,
      loading: loading,
      onTap: loading ? null : onTap,
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
  });
  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.1, end: 0, duration: 200.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login screen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  int _shakeKey = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _shake() => setState(() => _shakeKey++);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
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
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      context.go(AppRoute.home);
    } else if (result.fieldErrors?['email'] == 'not_verified' ||
        result.message.toLowerCase().contains('verify')) {
      context.push(AppRoute.otp, extra: {'email': _emailCtrl.text.trim()});
    } else {
      setState(() => _error = result.message);
      _shake();
      HapticFeedback.heavyImpact();
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    ref.read(authProvider.notifier).skipAsGuest();
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.9),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        IsharaAuthLogo(
                          teal: teal,
                          orange: orange,
                          theme: theme,
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1, 1),
                              duration: IsharaMotion.slow,
                              curve: IsharaMotion.overshoot,
                            )
                            .fadeIn(duration: IsharaMotion.slow),
                        const SizedBox(height: 28),
                        Text(
                          s.welcomeBack,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                            letterSpacing: -0.6,
                          ),
                        ).animate().fadeIn(
                              delay: 220.ms,
                              duration: IsharaMotion.base,
                            ),
                        const SizedBox(height: 6),
                        Text(
                          s.signInToContinue,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(
                              delay: 300.ms,
                              duration: IsharaMotion.base,
                            ),
                        const SizedBox(height: 36),

                        // Form
                        AuthFieldsShaker(
                          shakeKey: _shakeKey,
                          child: Column(
                            children: [
                              AuthField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                hint: s.emailAddress,
                                icon: Icons.email_outlined,
                                isDark: isDark,
                                teal: teal,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return s.emailRequired;
                                  }
                                  if (!v.contains('@')) return s.invalidEmail;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              AuthField(
                                controller: _passwordCtrl,
                                focusNode: _passwordFocus,
                                hint: s.password,
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                teal: teal,
                                obscure: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _login(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return s.passwordRequired;
                                  }
                                  if (v.length < 6) return s.tooShort;
                                  return null;
                                },
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                AuthErrorBanner(
                                  message: _error!,
                                  isDark: isDark,
                                ),
                                if (_error!.toLowerCase().contains('reach') ||
                                    _error!
                                        .toLowerCase()
                                        .contains('connect')) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push(AppRoute.serverConfig),
                                    icon: const Icon(
                                      Icons.dns_outlined,
                                      size: 18,
                                    ),
                                    label:
                                        const Text('Configure server address'),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ).animate().fadeIn(
                              delay: 380.ms,
                              duration: IsharaMotion.base,
                            ),

                        const SizedBox(height: 24),

                        GradientAuthButton(
                          label: s.signIn,
                          loading: _loading,
                          isDark: isDark,
                          onTap: _login,
                        ).animate().fadeIn(
                              delay: 460.ms,
                              duration: IsharaMotion.base,
                            ),

                        const SizedBox(height: 18),

                        TextButton(
                          onPressed: _loading ? null : _skip,
                          child: Text(
                            s.skipForNow,
                            style: TextStyle(
                              color: isDark
                                  ? IsharaColors.mutedDark
                                  : IsharaColors.mutedLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ).animate().fadeIn(
                              delay: 540.ms,
                              duration: IsharaMotion.base,
                            ),

                        const Spacer(),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.noAccount,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: isDark
                                      ? IsharaColors.mutedDark
                                      : IsharaColors.mutedLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => context.push(AppRoute.register),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(
                                    IsharaColors.minTouchTarget,
                                    IsharaColors.minTouchTarget,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                ),
                                child: Text(
                                  s.signUp,
                                  style: TextStyle(
                                    color: teal,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              delay: 620.ms,
                              duration: IsharaMotion.base,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
