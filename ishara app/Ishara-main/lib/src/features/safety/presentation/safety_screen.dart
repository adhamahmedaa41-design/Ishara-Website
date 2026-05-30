import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../../core/routing/app_router.dart';
import '../data/contacts_repository.dart';
import 'safety_controller.dart';

enum SafetyInitialTab { dashboard, sos }

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key, this.initialTab = SafetyInitialTab.dashboard});
  final SafetyInitialTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(safetyControllerProvider);
    final controller = ref.read(safetyControllerProvider.notifier);
    final s = t(ref);

    if (initialTab == SafetyInitialTab.sos) {
      return _SosFullScreen(
        state: state,
        controller: controller,
        theme: theme,
        isDark: isDark,
      );
    }

    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Aurora — danger-toned (red glow blob)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    right: -80,
                    child: IsharaGlowBlob(
                      size: 380,
                      color: const Color(0xFFEF4444),
                      opacity: 0.22,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: -6,
                          end: 6,
                          duration: 4400.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    top: 240,
                    left: -100,
                    child: IsharaGlowBlob(
                      size: 300,
                      color: const Color(0xFFF97316),
                      opacity: 0.18,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                          begin: 6,
                          end: -6,
                          duration: 5200.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: IsharaHero(
                    eyebrow: 'Safety',
                    title: s.safetyTitle,
                    description: s.safetySub,
                    icon: Icons.shield_rounded,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // SOS hero block
                      _SosHeroBlock(
                        sosLabel: s.sosEmergency,
                        sosSubLabel: s.tapToOpenSos,
                        onTap: () =>
                            _triggerAndShare(context, ref, controller),
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 80.ms,
                          ),

                      const SizedBox(height: IsharaSpacing.sectionGap),

                      const IsharaSectionLabel(
                        'Hardware sensor',
                        icon: Icons.sensors_rounded,
                      ),
                      _ObstacleCard(
                        state: state,
                        isDark: isDark,
                        theme: theme,
                        teal: teal,
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 160.ms,
                          ),

                      const SizedBox(height: IsharaSpacing.sectionGap),

                      const IsharaSectionLabel(
                        'Emergency contacts',
                        icon: Icons.contact_phone_rounded,
                      ),
                      _EmergencyContactCard(
                        isDark: isDark,
                        teal: teal,
                        theme: theme,
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 220.ms,
                          ),

                      if (state.error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shakeX(duration: 400.ms),
                      ],
                    ]),
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

// ─── SOS hero block — display number + giant pulse button ────────────────────
class _SosHeroBlock extends StatelessWidget {
  const _SosHeroBlock({
    required this.sosLabel,
    required this.sosSubLabel,
    required this.onTap,
  });
  final String sosLabel;
  final String sosSubLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IsharaSurface(
      variant: IsharaSurfaceVariant.dark,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      glow: false,
      child: Column(
        children: [
          Row(
            children: [
              const IsharaStatusPill(
                label: 'SOS READY',
                tone: IsharaStatusTone.danger,
                pulse: true,
              ),
              const Spacer(),
              Text(
                'Tap to alert',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SosBigButton(
            isDark: isDark,
            sosLabel: sosLabel,
            sosSubLabel: sosSubLabel,
            onTap: onTap,
          )
              .animate()
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: IsharaMotion.slow,
                curve: IsharaMotion.overshoot,
              )
              .fadeIn(duration: IsharaMotion.slow),
          const SizedBox(height: 18),
          Text(
            'Sends live location to every emergency contact',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SOS button ──────────────────────────────────────────────────────────────
class _SosBigButton extends StatefulWidget {
  const _SosBigButton({
    required this.isDark,
    required this.sosLabel,
    required this.sosSubLabel,
    required this.onTap,
  });
  final bool isDark;
  final String sosLabel;
  final String sosSubLabel;
  final VoidCallback onTap;

  @override
  State<_SosBigButton> createState() => _SosBigButtonState();
}

class _SosBigButtonState extends State<_SosBigButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.sosLabel,
      hint: widget.sosSubLabel,
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            widget.onTap();
          },
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final glow = 0.25 + _pulseCtrl.value * 0.35;
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: glow),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emergency_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.sosLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Obstacle card ────────────────────────────────────────────────────────────
class _ObstacleCard extends ConsumerWidget {
  const _ObstacleCard({
    required this.state,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final SafetyState state;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final hasData = state.obstacleReading != null;
    final isClose = hasData && state.obstacleReading!.distanceCm < 40;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassmorphismDecoration(dark: isDark).copyWith(
        border: Border.all(
          color:
              isClose
                  ? theme.colorScheme.error.withValues(alpha: 0.4)
                  : (isDark
                      ? IsharaColors.darkBorder
                      : IsharaColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isClose ? theme.colorScheme.error : teal).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: isClose ? theme.colorScheme.error : teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.obstacleDetection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Source badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (state.glassesConnected
                          ? teal
                          : theme.colorScheme.outline)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.glassesConnected
                          ? Icons.bluetooth_connected
                          : Icons.sim_card_alert_outlined,
                      size: 12,
                      color:
                          state.glassesConnected
                              ? teal
                              : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.glassesConnected ? s.live : s.simulated,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            state.glassesConnected
                                ? teal
                                : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasData) ...[
            _SensorRow(
              label: s.distance,
              value: '${state.obstacleReading!.distanceCm} cm',
              teal: teal,
              theme: theme,
            ),
            if (state.obstacleReading!.leftCm != null)
              _SensorRow(
                label: s.left,
                value: '${state.obstacleReading!.leftCm} cm',
                teal: teal,
                theme: theme,
              ),
            if (state.obstacleReading!.rightCm != null)
              _SensorRow(
                label: s.right,
                value: '${state.obstacleReading!.rightCm} cm',
                teal: teal,
                theme: theme,
              ),
            if (isClose) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s.obstacleNearby,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ).animate().shakeX(duration: 400.ms),
            ],
          ] else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.connectHardware,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoute.hardwarePairing),
                    icon: const Icon(Icons.bluetooth_searching_rounded),
                    label: Text(s.pairHardware),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({
    required this.label,
    required this.value,
    required this.teal,
    required this.theme,
  });
  final String label, value;
  final Color teal;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: teal),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS Full Screen – enhanced with pulsing glow button
// ─────────────────────────────────────────────────────────────────────────────
class _SosFullScreen extends ConsumerWidget {
  const _SosFullScreen({
    required this.state,
    required this.controller,
    required this.theme,
    required this.isDark,
  });
  final SafetyState state;
  final SafetyController controller;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final isSending = state.sosPhase == SosPhase.sending;
    final isSent = state.sosPhase == SosPhase.sent;
    final hasError = state.error != null && state.sosPhase == SosPhase.sent;
    // Read contacts from the already-loaded provider plus the synchronous
    // local cache fallback — guarantees offline-saved contacts are visible.
    final contactsAsync = ref.watch(contactsListProvider);
    final repo = ref.read(contactsRepositoryProvider);
    final cachedNow = repo.cachedNow();
    final hasContacts = contactsAsync.maybeWhen(
      data: (list) => list.isNotEmpty || cachedNow.isNotEmpty,
      orElse: () => cachedNow.isNotEmpty,
    );

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A0505) : const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // ── Close ─────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      controller.resetSos();
                      context.pop();
                    },
                  ),
                  const Spacer(),
                ],
              ),

              const Spacer(),

              // ── Status title ───────────────────────────────────────────
              Text(
                isSent
                    ? (hasError ? 'Send failed' : s.helpSent)
                    : isSending
                        ? 'Sending…'
                        : s.sosEmergencyTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: (isSent && !hasError)
                      ? (isDark
                          ? IsharaColors.tealDark
                          : IsharaColors.tealLight)
                      : const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 8),

              Text(
                isSent
                    ? (hasError
                        ? (state.error ?? '')
                        : s.locationSentMsg)
                    : isSending
                        ? 'Emailing your emergency contacts…'
                        : 'Press the button to send your live location to your emergency contacts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

              const Spacer(),

              // ── Main action area ───────────────────────────────────────
              if (isSending)
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Color(0xFFEF4444),
                  ),
                )
              else if (isSent) ...[
                Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_rounded,
                      size: 96,
                      color: hasError
                          ? const Color(0xFFEF4444)
                          : (isDark
                              ? IsharaColors.tealDark
                              : IsharaColors.tealLight),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 300.ms),

                if (state.lastSosLocation != null && !hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Lat: ${state.lastSosLocation!.latitude.toStringAsFixed(4)}  '
                    'Lng: ${state.lastSosLocation!.longitude.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (!hasError) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Also share via',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShareChip(
                        icon: Icons.chat_rounded,
                        label: 'WhatsApp',
                        bg: const Color(0xFF25D366),
                        onTap: () => _shareSosVia(
                          context,
                          ref,
                          channel: _ShareChannel.whatsapp,
                          location: state.lastSosLocation,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ShareChip(
                        icon: Icons.send_rounded,
                        label: 'Telegram',
                        bg: const Color(0xFF229ED9),
                        onTap: () => _shareSosVia(
                          context,
                          ref,
                          channel: _ShareChannel.telegram,
                          location: state.lastSosLocation,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ShareChip(
                        icon: Icons.sms_rounded,
                        label: 'SMS',
                        bg: const Color(0xFF6366F1),
                        onTap: () => _shareSosVia(
                          context,
                          ref,
                          channel: _ShareChannel.sms,
                          location: state.lastSosLocation,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                _SosActionButton(
                  label: s.done,
                  color: isDark
                      ? IsharaColors.tealDark
                      : IsharaColors.tealLight,
                  onTap: () {
                    controller.resetSos();
                    context.pop();
                  },
                ),
              ] else ...[
                _PulsingSosCircle(
                  onTap: () async {
                    if (!hasContacts) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(s.noContactsSet),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: s.addContact,
                            onPressed: () => context.push(AppRoute.contacts),
                          ),
                        ),
                      );
                      return;
                    }
                    await controller.triggerSos();
                  },
                  onLongPress: () {},
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap to send SOS email',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing red circle SOS trigger
class _PulsingSosCircle extends StatefulWidget {
  const _PulsingSosCircle({required this.onTap, required this.onLongPress});
  final VoidCallback onTap, onLongPress;

  @override
  State<_PulsingSosCircle> createState() => _PulsingSosCircleState();
}

class _PulsingSosCircleState extends State<_PulsingSosCircle>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _ring1Ctrl;
  late final AnimationController _ring2Ctrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: 1400.ms)
      ..repeat(reverse: true);
    _ring1Ctrl = AnimationController(vsync: this, duration: 1800.ms)
      ..repeat();
    _ring2Ctrl = AnimationController(vsync: this, duration: 1800.ms)
      ..forward(from: 0.5)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _ring2Ctrl.repeat();
      });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _ring1Ctrl.dispose();
    _ring2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);
    return Semantics(
      button: true,
      label: 'SOS trigger',
      hint: 'Tap to arm, long press to send immediately',
      child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onTap();
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              widget.onLongPress();
            },
            child: SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: Listenable.merge([_glowCtrl, _ring1Ctrl, _ring2Ctrl]),
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // ── Outer ripple ring 1 ─────────────────────────
                      Opacity(
                        opacity: (1 - _ring1Ctrl.value).clamp(0.0, 1.0),
                        child: Container(
                          width: 172 + _ring1Ctrl.value * 68,
                          height: 172 + _ring1Ctrl.value * 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: red.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // ── Outer ripple ring 2 (staggered) ────────────
                      Opacity(
                        opacity: (1 - _ring2Ctrl.value).clamp(0.0, 1.0),
                        child: Container(
                          width: 172 + _ring2Ctrl.value * 68,
                          height: 172 + _ring2Ctrl.value * 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: red.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // ── Main button ─────────────────────────────────
                      Container(
                        width: 172,
                        height: 172,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFD32F2F)],
                            center: Alignment(-0.3, -0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: red.withValues(
                                  alpha: 0.3 + _glowCtrl.value * 0.3),
                              blurRadius: 28 + _glowCtrl.value * 18,
                              spreadRadius: 2 + _glowCtrl.value * 6,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emergency_rounded,
                                size: 72, color: Colors.white),
                            const SizedBox(height: 4),
                            Text(
                              'SOS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 400.ms),
    );
  }
}

class _SosActionButton extends StatelessWidget {
  const _SosActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends ConsumerStatefulWidget {
  const _EmergencyContactCard({
    required this.isDark,
    required this.teal,
    required this.theme,
  });

  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  ConsumerState<_EmergencyContactCard> createState() =>
      _EmergencyContactCardState();
}

class _EmergencyContactCardState extends ConsumerState<_EmergencyContactCard> {
  // ID of the contact being edited; empty string = adding a new contact;
  // null = list view (no form open).
  String? _editingId;
  bool _saving = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh from server on first build so the list reflects the database.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures
      ref.read(contactsRepositoryProvider).list(forceRefresh: true).then((_) {
        if (mounted) ref.invalidate(contactsListProvider);
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _openAddForm() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    setState(() => _editingId = '');
  }

  void _openEditForm(EmergencyContactDto c) {
    _nameCtrl.text = c.name;
    _phoneCtrl.text = c.phone;
    _emailCtrl.text = c.email;
    setState(() => _editingId = c.id);
  }

  void _cancelForm() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    setState(() => _editingId = null);
  }

  Future<void> _saveContact() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showSnack(
        message: 'Please enter both contact name and phone number.',
        success: false,
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showSnack(
        message:
            'Please enter a valid email — SOS sends an email to this address.',
        success: false,
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(contactsRepositoryProvider);
    final isEditing = _editingId != null && _editingId!.isNotEmpty;
    final dto = EmergencyContactDto(
      id: isEditing ? _editingId! : '',
      name: name,
      phone: phone,
      email: email,
    );

    if (isEditing) {
      await repo.update(dto);
    } else {
      await repo.add(dto);
    }
    ref.invalidate(contactsListProvider);

    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _editingId = null;
      _saving = false;
    });
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();
    _showSnack(
      message: isEditing ? 'Contact updated.' : 'Contact added.',
      success: true,
    );
  }

  Future<void> _deleteContact(EmergencyContactDto c) async {
    HapticFeedback.mediumImpact();
    final repo = ref.read(contactsRepositoryProvider);
    await repo.remove(c.id);
    ref.invalidate(contactsListProvider);
    if (!mounted) return;
    _showSnack(message: '${c.name} removed.', success: true);
  }

  void _showSnack({required String message, required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? widget.teal : widget.theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(contactsListProvider);
    final repo = ref.read(contactsRepositoryProvider);
    final contacts = asyncList.maybeWhen(
      data: (list) => list,
      orElse: () => repo.cachedNow(),
    );
    final isDark = widget.isDark;
    final teal = widget.teal;
    final isFormOpen = _editingId != null;
    const red = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassmorphismDecoration(
        dark: isDark,
      ).copyWith(border: Border.all(color: red.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  size: 18,
                  color: red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency Contacts (${contacts.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (!isFormOpen)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _openAddForm();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.12),
                      borderRadius: IsharaColors.pillRadius,
                      border: Border.all(color: teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: teal),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            color: teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Contact list ─────────────────────────────────────────────
          if (contacts.isEmpty && !isFormOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No emergency contacts yet. Tap Add to create one.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? IsharaColors.mutedDark
                      : IsharaColors.mutedLight,
                ),
              ),
            ),
          for (final c in contacts) ...[
            _ContactRow(
              dto: c,
              isDark: isDark,
              red: red,
              teal: teal,
              onEdit: () {
                HapticFeedback.selectionClick();
                _openEditForm(c);
              },
              onDelete: () => _deleteContact(c),
            ),
            const SizedBox(height: 10),
          ],

          // ── Add / edit form ─────────────────────────────────────────
          if (isFormOpen) ...[
            const SizedBox(height: 4),
            Text(
              _editingId!.isEmpty ? 'New contact' : 'Edit contact',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            _ContactField(
              ctrl: _nameCtrl,
              hintText: 'Contact name',
              icon: Icons.person_rounded,
              isDark: isDark,
              teal: teal,
            ),
            const SizedBox(height: 14),
            _ContactField(
              ctrl: _phoneCtrl,
              hintText: 'Phone number (e.g. 01012345678)',
              icon: Icons.phone_rounded,
              isDark: isDark,
              teal: teal,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _ContactField(
              ctrl: _emailCtrl,
              hintText: 'Email address (used for SOS alerts)',
              icon: Icons.email_rounded,
              isDark: isDark,
              teal: teal,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _cancelForm();
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingId!.isEmpty ? 'Add' : 'Save',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'SOS notifies every contact above via email, SMS, WhatsApp, and Telegram with your live location.',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.dto,
    required this.isDark,
    required this.red,
    required this.teal,
    required this.onEdit,
    required this.onDelete,
  });
  final EmergencyContactDto dto;
  final bool isDark;
  final Color red;
  final Color teal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dto.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(Icons.edit_rounded, size: 16, color: teal),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 13, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text(dto.phone, style: const TextStyle(fontSize: 13)),
            ],
          ),
          if (dto.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email_rounded, size: 13, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dto.email,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactField extends StatefulWidget {
  const _ContactField({
    required this.ctrl,
    required this.hintText,
    required this.icon,
    required this.isDark,
    required this.teal,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String hintText;
  final IconData icon;
  final bool isDark;
  final Color teal;
  final TextInputType? keyboardType;

  @override
  State<_ContactField> createState() => _ContactFieldState();
}

class _ContactFieldState extends State<_ContactField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: IsharaColors.cardRadius,
        color:
            widget.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
        border: Border.all(
          color:
              _focused
                  ? widget.teal.withValues(alpha: 0.6)
                  : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1)),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: widget.teal.withValues(alpha: 0.18),
                    blurRadius: 8,
                  ),
                ]
                : [],
      ),
      child: ClipRRect(
        borderRadius: IsharaColors.cardRadius,
        child: TextField(
          controller: widget.ctrl,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? widget.teal : widget.teal.withValues(alpha: 0.6),
              size: 18,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Post-SOS share helpers (WhatsApp / Telegram / SMS deep-links) ──────────
//
// These open the chosen messenger with the SOS message pre-filled. The user
// still has to tap send inside that app — neither WhatsApp nor Telegram
// allow third-party silent sending for personal accounts, so this is the
// best UX possible for those channels. SMS uses the system compose sheet.

/// Triggers the multi-channel SOS dispatch (email + Android silent SMS +
/// server-routed WhatsApp/Telegram if Twilio is configured) AND opens a
/// bottom sheet so the user can fire WhatsApp/Telegram/SMS deep-links by
/// hand. This is the one-tap entry from the Safety dashboard.
Future<void> _triggerAndShare(
  BuildContext context,
  WidgetRef ref,
  SafetyController controller,
) async {
  // Pull from the server before deciding "no contacts" so a cold start
  // (cache empty, contacts saved server-side) doesn't block SOS.
  final repo = ref.read(contactsRepositoryProvider);
  List<EmergencyContactDto> contacts = repo.cachedNow();
  if (contacts.isEmpty) {
    try {
      contacts = await repo.list(forceRefresh: true);
    } catch (_) {
      // Network may be down — fall back to whatever's cached.
      contacts = repo.cachedNow();
    }
  }

  if (contacts.isEmpty) {
    if (!context.mounted) return;
    final s = t(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.noContactsSet),
        action: SnackBarAction(
          label: s.addContact,
          onPressed: () => context.push(AppRoute.contacts),
        ),
      ),
    );
    return;
  }

  // Fire all silent channels (email + Android SMS + server) — fire-and-forget
  // so the share sheet appears immediately.
  unawaited(controller.triggerSos());

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      final isDark = theme.brightness == Brightness.dark;
      final teal =
          isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF22C55E), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SOS dispatched',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Email is being sent to your emergency contacts. '
              'Tap a button below to also notify them via WhatsApp, '
              'Telegram, or SMS — your message is pre-filled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _ShareChip(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  bg: const Color(0xFF25D366),
                  onTap: () => _shareSosVia(
                    sheetCtx,
                    ref,
                    channel: _ShareChannel.whatsapp,
                    location: ref.read(safetyControllerProvider).lastSosLocation,
                  ),
                ),
                _ShareChip(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  bg: const Color(0xFF229ED9),
                  onTap: () => _shareSosVia(
                    sheetCtx,
                    ref,
                    channel: _ShareChannel.telegram,
                    location: ref.read(safetyControllerProvider).lastSosLocation,
                  ),
                ),
                _ShareChip(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  bg: const Color(0xFF6366F1),
                  onTap: () => _shareSosVia(
                    sheetCtx,
                    ref,
                    channel: _ShareChannel.sms,
                    location: ref.read(safetyControllerProvider).lastSosLocation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    },
  );
}

enum _ShareChannel { whatsapp, telegram, sms }

Future<void> _shareSosVia(
  BuildContext context,
  WidgetRef ref, {
  required _ShareChannel channel,
  required Position? location,
}) async {
  final contacts = ref.read(contactsRepositoryProvider).cachedNow();
  if (contacts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No emergency contact saved.')),
    );
    return;
  }

  // If the SOS dispatch hasn't captured a position yet (the sheet opens
  // before triggerSos resolves), grab one now so the message ALWAYS has
  // a Google Maps link.
  Position? loc = location;
  if (loc == null) {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      loc = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      try {
        loc = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }
  }

  final mapsUrl = loc == null
      ? ''
      : 'https://maps.google.com/?q=${loc.latitude},${loc.longitude}';
  final body = '🚨 SOS — I need help.'
      '${mapsUrl.isNotEmpty ? "\nLocation: $mapsUrl" : ""}\n\n'
      '🚨 طلب مساعدة طارئ. أحتاج المساعدة فوراً.'
      '${mapsUrl.isNotEmpty ? "\nالموقع: $mapsUrl" : ""}';
  final encoded = Uri.encodeComponent(body);

  // Open one deep-link per contact. WhatsApp/Telegram allow multiple
  // tabs/windows; SMS uses the system compose sheet.
  int opened = 0;
  for (final c in contacts) {
    final phoneDigits = c.phone.replaceAll(RegExp(r'[^\d]'), '');
    Uri uri;
    switch (channel) {
      case _ShareChannel.whatsapp:
        uri = Uri.parse('https://wa.me/$phoneDigits?text=$encoded');
        break;
      case _ShareChannel.telegram:
        uri = Uri.parse('https://t.me/+$phoneDigits?text=$encoded');
        break;
      case _ShareChannel.sms:
        uri = Uri.parse('sms:${c.phone}?body=$encoded');
        break;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) opened++;
    } catch (_) {
      // Skip this contact, continue with the next.
    }
    // SMS only supports one compose at a time on most platforms — break
    // after the first launch to avoid stacking dialogs.
    if (channel == _ShareChannel.sms) break;
  }

  if (opened == 0 && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open ${channel.name}.')),
    );
  }
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

