import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hardware/hardware_connection_service.dart';
import '../../../core/hardware/glasses_provider.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../../core/widgets/ishara_feedback.dart';

class HardwarePairingScreen extends ConsumerStatefulWidget {
  const HardwarePairingScreen({super.key});

  @override
  ConsumerState<HardwarePairingScreen> createState() =>
      _HardwarePairingScreenState();
}

class _HardwarePairingScreenState extends ConsumerState<HardwarePairingScreen> {
  final _hostController = TextEditingController(text: '192.168.4.1');
  final _portController = TextEditingController(text: '8080');
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });
    try {
      final port = int.parse(_portController.text.trim());
      await ref
          .read(hardwareServiceProvider)
          .connect(_hostController.text.trim(), port);
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(ref).connectedToGlasses)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _disconnect() {
    ref.read(hardwareServiceProvider).disconnect();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final stateAsync = ref.watch(hardwareStateProvider);
    final sensorAsync = ref.watch(glassesSensorProvider);
    final recordingAsync = ref.watch(glassesRecordingProvider);

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
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.6),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IsharaHero(
                    eyebrow: 'Hardware',
                    title: s.pairGlasses,
                    description: s.glassesInstructions,
                    icon: Icons.bluetooth_connected_rounded,
                  ),

                  // ── Status pill ───────────────────────────────────
                  stateAsync.when(
                    data: (state) {
                      late final String label;
                      late final IsharaStatusTone tone;
                      late final bool pulse;
                      switch (state) {
                        case HardwareConnectionState.connected:
                          label = s.connected;
                          tone = IsharaStatusTone.good;
                          pulse = false;
                          break;
                        case HardwareConnectionState.connecting:
                          label = s.connecting;
                          tone = IsharaStatusTone.warn;
                          pulse = true;
                          break;
                        case HardwareConnectionState.disconnected:
                          label = 'Disconnected';
                          tone = IsharaStatusTone.neutral;
                          pulse = false;
                          break;
                        case HardwareConnectionState.error:
                          label = 'Error';
                          tone = IsharaStatusTone.danger;
                          pulse = true;
                          break;
                      }
                      return Row(
                        children: [
                          IsharaStatusPill(
                            label: label,
                            tone: tone,
                            pulse: pulse,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── IP / port inputs ──────────────────────────────
                  _PairField(
                    controller: _hostController,
                    label: s.glassesIp,
                    icon: Icons.wifi_outlined,
                  ),
                  const SizedBox(height: 10),
                  _PairField(
                    controller: _portController,
                    label: s.port,
                    icon: Icons.settings_ethernet_rounded,
                    keyboardType: TextInputType.number,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.32),
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
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Connect / Disconnect action ──────────────────
                  stateAsync.when(
                    data: (state) {
                      if (state == HardwareConnectionState.connected) {
                        return IsharaActionTile(
                          label: s.disconnect,
                          icon: Icons.link_off_rounded,
                          variant: IsharaActionVariant.outline,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _disconnect();
                          },
                        );
                      }
                      return IsharaActionTile(
                        label: _isConnecting ? s.connecting : s.connect,
                        icon: Icons.link_rounded,
                        loading: _isConnecting,
                        onTap: _isConnecting ||
                                state ==
                                    HardwareConnectionState.connecting
                            ? null
                            : _connect,
                      );
                    },
                    loading: () => IsharaLoadingState(
                      message: s.testing,
                      compact: true,
                    ),
                    error: (_, __) => IsharaActionTile(
                      label: s.retryConnect,
                      icon: Icons.refresh_rounded,
                      onTap: _isConnecting ? null : _connect,
                    ),
                  ),

                  const SizedBox(height: IsharaSpacing.sectionGap),

                  // ── Live status when connected ───────────────────
                  stateAsync.when(
                    data: (state) {
                      if (state !=
                          HardwareConnectionState.connected) {
                        return IsharaSurface(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bluetooth_disabled_rounded,
                                size: 36,
                                color: teal.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.glassesStatus,
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Not connected yet. Use the fields above to connect your glasses.',
                                textAlign: TextAlign.center,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? IsharaColors.mutedDark
                                      : IsharaColors.mutedLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IsharaSectionLabel(
                            s.glassesStatus,
                            icon: Icons.sensors_rounded,
                          ),

                          // Sensor card
                          IsharaSurface(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: teal.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.sensors_rounded,
                                    color: teal,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: sensorAsync.when(
                                    data: (msg) {
                                      final cm = msg.payload?['distance_cm'];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Obstacle distance',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: isDark
                                                  ? IsharaColors.mutedDark
                                                  : IsharaColors.mutedLight,
                                              letterSpacing: 0.4,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${cm ?? '—'} cm',
                                            style: theme
                                                .textTheme.headlineSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 22,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => Text(s.waitingSensor),
                                    error: (_, __) => Text(s.sensorError),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Recording card
                          IsharaSurface(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: recordingAsync.when(
                                    data: (isRec) => Text(
                                      isRec
                                          ? s.glassesMicRecording
                                          : s.glassesMicIdle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    loading: () => Text(s.micIdle),
                                    error: (_, __) => const Text('—'),
                                  ),
                                ),
                                recordingAsync.when(
                                  data: (isRec) => GestureDetector(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      final hw = ref.read(
                                        hardwareServiceProvider,
                                      );
                                      isRec
                                          ? hw.stopRecording()
                                          : hw.startRecording();
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: isRec
                                            ? null
                                            : LinearGradient(colors: [
                                                teal,
                                                isDark
                                                    ? IsharaColors.orangeDark
                                                    : IsharaColors
                                                        .orangeLight,
                                              ]),
                                        color: isRec
                                            ? const Color(0xFFEF4444)
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isRec
                                            ? Icons.stop_rounded
                                            : Icons
                                                .fiber_manual_record_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) =>
                                      const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Vibrate test
                          IsharaActionTile(
                            label: s.testVibration,
                            icon: Icons.vibration_rounded,
                            variant: IsharaActionVariant.outline,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(hardwareServiceProvider)
                                  .vibrate(pattern: 'short_pulse');
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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

class _PairField extends StatelessWidget {
  const _PairField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: teal),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor:
            isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? IsharaColors.darkBorder
                : IsharaColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? IsharaColors.darkBorder
                : IsharaColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: teal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }
}
