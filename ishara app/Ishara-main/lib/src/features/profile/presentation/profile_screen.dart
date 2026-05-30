import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/api/auth_service.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/ishara_feedback.dart';
import '../../../core/widgets/ishara_design_system.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  late TextEditingController _nameCtrl;
  String _selectedDisability = 'deaf';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _startEditing(IsharaUser? user) {
    setState(() {
      _isEditing = true;
      _nameCtrl.text = user?.name ?? '';
      _selectedDisability = user?.disabilityType ?? 'deaf';
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final dataService = ref.read(dataServiceProvider);
    await dataService.updateProfile(
      name: _nameCtrl.text.trim(),
      disabilityType: _selectedDisability,
    );
    await ref.read(authProvider.notifier).refreshUser();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t(ref).profileUpdated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final dataService = ref.read(dataServiceProvider);
      final result = await dataService.updateAvatar(xFile.path);
      if (!mounted) return;
      if (result.success) {
        // Refresh user so the returned Cloudinary URL is persisted correctly.
        // The server always stores an absolute URL (Cloudinary in prod, or
        // server-relative on local dev). refreshUser() saves it to local cache.
        await ref.read(authProvider.notifier).refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(ref).avatarUpdated),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Photo upload failed: ${result.message}. '
                'Make sure Cloudinary is configured on the server for cross-device photos.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _logout() async {
    final s = t(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(s.logout),
            content: Text(s.logoutConfirm),
            actions: [
              TextButton(
                onPressed: () => ctx.pop(false),
                child: Text(s.cancel),
              ),
              TextButton(onPressed: () => ctx.pop(true), child: Text(s.logout)),
            ],
          ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    // Profile-pic editing requires a real account — guests / unauthenticated
    // users see a read-only avatar and no "add photo" prompts.
    final canEditAvatar = authState.isLoggedIn && user != null;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(children: [
        const IsharaAuroraBackground(intensity: 0.6),
        CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Profile header with avatar ─────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              isDark: isDark,
              theme: theme,
              teal: teal,
              orange: orange,
              user: user,
              isUploadingAvatar: _isUploadingAvatar,
              // Tap is a no-op (null) when the user isn't logged in, which
              // also hides the camera-edge badge in the header widget.
              onAvatarTap: canEditAvatar && !_isUploadingAvatar ? _pickAvatar : null,
            ),
          ),

          // ── No-photo banner ──────────────────────────────────────────
          if (canEditAvatar && user.profilePic.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: MaterialBanner(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  content: Text(s.addPhotoPrompt),
                  leading: const Icon(Icons.add_a_photo_rounded),
                  actions: [
                    TextButton(
                      onPressed: _pickAvatar,
                      child: Text(s.addPhoto),
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── User info / edit card ──────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 80.ms,
                  child:
                      _isEditing
                          ? _EditProfileForm(
                            nameCtrl: _nameCtrl,
                            selectedDisability: _selectedDisability,
                            isSaving: _isSaving,
                            teal: teal,
                            isDark: isDark,
                            theme: theme,
                            onDisabilityChanged:
                                (v) => setState(() => _selectedDisability = v),
                            onSave: _saveProfile,
                            onCancel: () => setState(() => _isEditing = false),
                          )
                          : user == null
                          ? _GuestProfilePrompt(
                            teal: teal,
                            onTap: () => context.go(AppRoute.login),
                          )
                          : _UserInfoDisplay(
                            user: user,
                            teal: teal,
                            orange: orange,
                            isDark: isDark,
                            theme: theme,
                            onEdit: () => _startEditing(user),
                          ),
                ),

                const SizedBox(height: 16),

                // ── Appearance ──────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 180.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.palette_outlined,
                        label: s.appearance,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ThemePill(
                            label: s.light,
                            icon: Icons.light_mode_rounded,
                            selected: settings.themeMode == ThemeMode.light,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.light),
                          ),
                          const SizedBox(width: 10),
                          _ThemePill(
                            label: s.dark,
                            icon: Icons.dark_mode_rounded,
                            selected: settings.themeMode == ThemeMode.dark,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.dark),
                          ),
                          const SizedBox(width: 10),
                          _ThemePill(
                            label: s.system,
                            icon: Icons.brightness_auto_rounded,
                            selected: settings.themeMode == ThemeMode.system,
                            teal: teal,
                            onTap: () => notifier.setTheme(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Language ───────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 260.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.language_rounded,
                        label: s.language,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _LangChip(
                            label: 'English',
                            selected: settings.language == IsharaLanguage.en,
                            teal: teal,
                            onTap:
                                () => notifier.setLanguage(IsharaLanguage.en),
                          ),
                          const SizedBox(width: 10),
                          _LangChip(
                            label: 'العربية',
                            selected: settings.language == IsharaLanguage.ar,
                            teal: teal,
                            onTap:
                                () => notifier.setLanguage(IsharaLanguage.ar),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Accessibility ──────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 340.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.accessibility_new_rounded,
                        label: s.accessibility,
                        teal: teal,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.accessibilityDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isDark
                                  ? IsharaColors.mutedDark
                                  : IsharaColors.mutedLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.bluetooth_connected_rounded,
                        label: s.pairHardware,
                        subtitle: s.glassesOrCane,
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.hardwarePairing),
                      ),
                      _ActionRow(
                        icon: Icons.accessibility_new_rounded,
                        label: s.accessibilitySettings,
                        subtitle: s.accessibilitySettingsSub,
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.accessibility),
                      ),
                      _ActionRow(
                        icon: Icons.share_rounded,
                        label: s.socialLinks,
                        subtitle: s.socialLinksSub,
                        teal: teal,
                        isDark: isDark,
                        onTap: () => context.push(AppRoute.social),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── About ──────────────────────────────────────────────
                _SectionCard(
                  isDark: isDark,
                  delay: 420.ms,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        label: s.about,
                        teal: teal,
                      ),
                      const SizedBox(height: 14),
                      _ActionRow(
                        icon: Icons.article_outlined,
                        label: s.version,
                        subtitle: s.versionSub,
                        teal: teal,
                        isDark: isDark,
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                // ── Logout ─────────────────────────────────────────────
                const SizedBox(height: 24),
                IsharaActionTile(
                  label: s.logout,
                  icon: Icons.logout_rounded,
                  variant: IsharaActionVariant.danger,
                  trailingIcon: Icons.exit_to_app_rounded,
                  onTap: _logout,
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
              ]),
            ),
          ),
        ],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header – large gradient avatar area with real user data
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.isDark,
    required this.theme,
    required this.teal,
    required this.orange,
    required this.user,
    this.onAvatarTap,
    this.isUploadingAvatar = false,
  });
  final bool isDark;
  final ThemeData theme;
  final Color teal;
  final Color orange;
  final IsharaUser? user;
  final VoidCallback? onAvatarTap;
  final bool isUploadingAvatar;

  static IconData _disabilityIcon(String? type) {
    switch (type) {
      case 'blind':
        return Icons.visibility_off_rounded;
      case 'deaf':
        return Icons.hearing_disabled_rounded;
      case 'non-verbal':
        return Icons.record_voice_over_rounded;
      default:
        return Icons.accessibility_new_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final topPad = MediaQuery.of(context).padding.top;
    final isVerified = user?.isVerified ?? false;
    final disabilityType = user?.disabilityType ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 24, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            teal.withValues(alpha: isDark ? 0.18 : 0.12),
            orange.withValues(alpha: isDark ? 0.06 : 0.04),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ─────────────────────────────────────────────────
          GestureDetector(
            onTap: onAvatarTap,
            child: Semantics(
              button: onAvatarTap != null,
              label: 'Profile picture',
              hint: onAvatarTap != null ? 'Tap to change profile picture' : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isharaDiagonalGradient(dark: isDark),
                          boxShadow: [
                            BoxShadow(
                              color: teal.withValues(alpha: 0.3),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: isDark
                                    ? IsharaColors.darkCard
                                    : Colors.white,
                                backgroundImage:
                                    user != null && user!.profilePic.isNotEmpty
                                        ? NetworkImage(user!.profilePic)
                                        : null,
                                child: user == null || user!.profilePic.isEmpty
                                    ? Icon(Icons.person_rounded,
                                        size: 42, color: teal)
                                    : null,
                              ),
                              // Loading overlay during avatar upload
                              if (isUploadingAvatar)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),
                  if (onAvatarTap != null && !isUploadingAvatar)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: teal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 13, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ── Name + email + badges ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => LinearGradient(
                    colors: [teal, orange],
                  ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text(
                    user?.name ?? s.user,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms)
                    .slideX(begin: 0.05, end: 0, delay: 80.ms, duration: 280.ms),

                const SizedBox(height: 2),

                // Email
                if (user?.email.isNotEmpty == true)
                  Text(
                    user!.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).animate().fadeIn(delay: 140.ms, duration: 350.ms),

                const SizedBox(height: 10),

                // ── Badge row ─────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Disability type badge
                    if (disabilityType.isNotEmpty)
                      _HeaderBadge(
                        icon: _disabilityIcon(disabilityType),
                        label: disabilityType.capitalize(),
                        color: teal,
                        isDark: isDark,
                      ),
                    // Verified badge
                    _HeaderBadge(
                      icon: isVerified
                          ? Icons.verified_rounded
                          : Icons.pending_outlined,
                      label: isVerified ? s.verified : s.notVerified,
                      color: isVerified ? teal : (isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight),
                      isDark: isDark,
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User info display ────────────────────────────────────────────────────────
class _UserInfoDisplay extends ConsumerWidget {
  const _UserInfoDisplay({
    required this.user,
    required this.teal,
    required this.orange,
    required this.isDark,
    required this.theme,
    required this.onEdit,
  });
  final IsharaUser? user;
  final Color teal, orange;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(
              icon: Icons.person_rounded,
              label: s.profileTitle,
              teal: teal,
            ),
            const Spacer(),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: IsharaColors.pillRadius,
                  border: Border.all(color: teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 14, color: teal),
                    const SizedBox(width: 4),
                    Text(
                      s.edit,
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.badge_outlined,
          label: s.name,
          value: user?.name ?? '—',
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.email_outlined,
          label: s.email,
          value: user?.email ?? '—',
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.accessibility_new_rounded,
          label: s.disabilityType,
          value: (user?.disabilityType ?? 'deaf').capitalize(),
          isDark: isDark,
          teal: teal,
        ),
        _InfoTile(
          icon: Icons.verified_outlined,
          label: s.status,
          value: (user?.isVerified ?? false) ? s.verified : s.notVerified,
          isDark: isDark,
          teal: teal,
        ),
      ],
    );
  }
}

class _GuestProfilePrompt extends ConsumerWidget {
  const _GuestProfilePrompt({required this.teal, required this.onTap});

  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return IsharaEmptyState(
      icon: Icons.person_outline_rounded,
      title: s.profileTitle,
      message: s.guestMessage,
      ctaLabel: s.guestLogin,
      onCtaTap: onTap,
      maxWidth: 420,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.teal,
  });
  final IconData icon;
  final String label, value;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: isDark
              ? IsharaColors.darkBorder
              : IsharaColors.lightBorder,
        ),
      ],
    );
  }
}

// ─── Edit profile form ────────────────────────────────────────────────────────
class _EditProfileForm extends ConsumerWidget {
  const _EditProfileForm({
    required this.nameCtrl,
    required this.selectedDisability,
    required this.isSaving,
    required this.teal,
    required this.isDark,
    required this.theme,
    required this.onDisabilityChanged,
    required this.onSave,
    required this.onCancel,
  });
  final TextEditingController nameCtrl;
  final String selectedDisability;
  final bool isSaving;
  final Color teal;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<String> onDisabilityChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  static const _disabilities = [
    'deaf',
    'blind',
    'non-verbal',
    'other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.edit_rounded,
          label: s.editProfile,
          teal: teal,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: s.fullName,
            prefixIcon: Icon(Icons.badge_outlined, color: teal, size: 20),
            border: OutlineInputBorder(borderRadius: IsharaColors.cardRadius),
            enabledBorder: OutlineInputBorder(
              borderRadius: IsharaColors.cardRadius,
              borderSide: BorderSide(
                color:
                    isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: IsharaColors.cardRadius,
              borderSide: BorderSide(color: teal),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.disabilityType,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _disabilities.map((d) {
                final selected = selectedDisability == d;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDisabilityChanged(d);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? teal : teal.withValues(alpha: 0.08),
                      borderRadius: IsharaColors.pillRadius,
                      border: Border.all(
                        color: selected ? teal : teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      d[0].toUpperCase() + d.substring(1),
                      style: TextStyle(
                        color: selected ? Colors.white : teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: Text(s.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child:
                    isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(s.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section card with animate entrance
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.isDark,
    required this.delay,
  });
  final Widget child;
  final bool isDark;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: glassmorphismDecoration(dark: isDark),
          padding: const EdgeInsets.all(20),
          child: child,
        )
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideY(begin: 0.15, end: 0, delay: delay, duration: 300.ms);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.teal,
  });
  final IconData icon;
  final String label;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: teal),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: teal,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.teal,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            color: selected ? teal : teal.withValues(alpha: 0.08),
            borderRadius: IsharaColors.cardRadius,
            border: Border.all(color: selected ? teal : teal.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : teal),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.teal,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color teal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(
          minHeight: IsharaColors.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? teal : teal.withValues(alpha: 0.08),
          borderRadius: IsharaColors.pillRadius,
          border: Border.all(color: selected ? teal : teal.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? Colors.white : teal,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.teal,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color teal;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap == null
              ? null
              : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 72,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: teal, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── String extension ─────────────────────────────────────────────────────────
extension _StringCap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
