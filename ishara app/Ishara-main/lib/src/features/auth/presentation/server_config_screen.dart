import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _ipCtrl = TextEditingController();
  bool _testing = false;
  String? _status; // null=idle, 'success', 'error:<msg>'

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final existing = prefs.getString('server_url');
    if (existing != null) {
      // Extract just the IP:port from a full URL
      final uri = Uri.tryParse(existing);
      _ipCtrl.text = uri?.host ?? existing;
    }
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      _testing = true;
      _status = null;
    });

    // Accept "192.168.1.25", "192.168.1.25:5000", or a full URL.
    String url;
    final raw = ip.replaceAll(RegExp(r'/+$'), '');
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      url = raw;
    } else if (raw.contains(':')) {
      url = 'http://$raw';
    } else {
      url = 'http://$raw:5000';
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          // Treat any HTTP response (even 404) as reachable — we just want
          // to confirm we can talk to the host.
          validateStatus: (_) => true,
        ),
      );
      final response = await dio.get('$url/api/health');
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 500) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setString('server_url', url);

        setState(() => _status = 'success');
        HapticFeedback.mediumImpact();

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go(AppRoute.login);
      } else {
        setState(() => _status = 'error:Server returned $code');
      }
    } catch (e) {
      setState(
        () => _status =
            'error:Could not reach $url. Make sure the backend is running and your phone is on the same Wi-Fi.',
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    final isSuccess = _status == 'success';
    final errorMsg =
        _status != null && _status!.startsWith('error:')
            ? _status!.substring(6)
            : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(children: [
        const IsharaAuroraBackground(intensity: 0.7),
        SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Hero icon ────────────────────────────────────────────
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
                child:
                    const Icon(Icons.dns_rounded, color: Colors.white, size: 46),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: IsharaMotion.slow,
                    curve: IsharaMotion.overshoot,
                  )
                  .fadeIn(duration: IsharaMotion.base),

              const SizedBox(height: 26),

              Text(
                'SERVER · SETUP',
                style: TextStyle(
                  color: teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ).animate().fadeIn(
                    delay: 80.ms,
                    duration: IsharaMotion.base,
                  ),
              const SizedBox(height: 10),
              Text(
                'Point Ishara at your server',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -0.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(
                    delay: 140.ms,
                    duration: IsharaMotion.base,
                  ),

              const SizedBox(height: 8),

              Text(
                'Enter the IP address of the computer\nrunning the Ishara backend.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? IsharaColors.mutedDark
                      : IsharaColors.mutedLight,
                  height: 1.5,
                ),
              ).animate().fadeIn(
                    delay: 200.ms,
                    duration: IsharaMotion.base,
                  ),

              const SizedBox(height: 32),

              // ── IP input ────────────────────────────────────────────────
              TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.25',
                  filled: true,
                  fillColor:
                      isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(
                      color:
                          isDark
                              ? IsharaColors.darkBorder
                              : IsharaColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: IsharaColors.cardRadius,
                    borderSide: BorderSide(color: teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onSubmitted: (_) => _testAndSave(),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 20),

              // ── Status ──────────────────────────────────────────────────
              if (isSuccess)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(0.1),
                    borderRadius: IsharaColors.cardRadius,
                    border: Border.all(color: teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Connected successfully!',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

              if (errorMsg != null)
                Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(
                          0.3,
                        ),
                        borderRadius: IsharaColors.cardRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMsg,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .shakeX(amount: 4, duration: 400.ms),

              const SizedBox(height: 24),

              // ── Connect button ──────────────────────────────────────────
              IsharaActionTile(
                label: 'Connect',
                icon: Icons.bolt_rounded,
                loading: _testing,
                onTap: _testing ? null : _testAndSave,
              ).animate().fadeIn(
                    delay: 320.ms,
                    duration: IsharaMotion.base,
                  ),

              const SizedBox(height: 14),

              // ── Skip for emulator ───────────────────────────────────────
              TextButton(
                onPressed: () async {
                  final prefs = ref.read(sharedPreferencesProvider);
                  await prefs.setString('server_url', 'http://10.0.2.2:5000');
                  if (mounted) context.go(AppRoute.login);
                },
                child: Text(
                  'Using Android emulator? Skip',
                  style: TextStyle(
                    color: isDark
                        ? IsharaColors.mutedDark
                        : IsharaColors.mutedLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      ]),
    );
  }
}
