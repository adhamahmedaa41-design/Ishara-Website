import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';

class ProfilePhotoSetupScreen extends ConsumerStatefulWidget {
  const ProfilePhotoSetupScreen({super.key});

  @override
  ConsumerState<ProfilePhotoSetupScreen> createState() =>
      _ProfilePhotoSetupScreenState();
}

class _ProfilePhotoSetupScreenState
    extends ConsumerState<ProfilePhotoSetupScreen> {
  File? _picked;
  bool _uploading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    HapticFeedback.selectionClick();
    final img = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (img == null) return;
    setState(() {
      _picked = File(img.path);
      _error = null;
    });
  }

  Future<void> _upload() async {
    final file = _picked;
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    final result =
        await ref.read(dataServiceProvider).updateAvatar(file.path);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result.success) {
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go(AppRoute.home);
    } else {
      setState(() => _error = result.message);
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.7),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'ALMOST · DONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                    ),
                  ).animate().fadeIn(duration: IsharaMotion.base),
                  const SizedBox(height: 10),
                  Text(
                    'Add a profile photo',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      letterSpacing: -0.6,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(
                        delay: 80.ms,
                        duration: IsharaMotion.base,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    'Help your contacts and the Ishara community recognise you. You can always skip this and add one later from the Profile tab.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(
                        delay: 160.ms,
                        duration: IsharaMotion.base,
                      ),
                  const SizedBox(height: 40),

                  // Avatar preview — gradient ring + glow
                  Center(
                    child: GestureDetector(
                      onTap: () => _pick(ImageSource.gallery),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 230,
                            height: 230,
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
                                duration: 2400.ms,
                                curve: Curves.easeInOut,
                              ),
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(6),
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
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _picked != null
                                  ? Image.file(_picked!,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: isDark
                                          ? const Color(0xFF0A0F1A)
                                          : Colors.white,
                                      child: Center(
                                        child: Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 48,
                                          color: teal,
                                        ),
                                      ),
                                    ),
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                duration: IsharaMotion.slow,
                                curve: IsharaMotion.overshoot,
                              )
                              .fadeIn(duration: IsharaMotion.slow),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Source buttons
                  Row(
                    children: [
                      Expanded(
                        child: IsharaActionTile(
                          label: 'Camera',
                          icon: Icons.camera_alt_rounded,
                          variant: IsharaActionVariant.outline,
                          trailingIcon: null,
                          onTap: () => _pick(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: IsharaActionTile(
                          label: 'Gallery',
                          icon: Icons.photo_library_rounded,
                          variant: IsharaActionVariant.outline,
                          trailingIcon: null,
                          onTap: () => _pick(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(
                        delay: 260.ms,
                        duration: IsharaMotion.base,
                      ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Save CTA
                  IsharaActionTile(
                    label: 'Save photo',
                    icon: Icons.check_rounded,
                    loading: _uploading,
                    onTap: _picked == null || _uploading ? null : _upload,
                  ).animate().fadeIn(
                        delay: 320.ms,
                        duration: IsharaMotion.base,
                      ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _uploading ? null : _skip,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: 380.ms,
                        duration: IsharaMotion.base,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
