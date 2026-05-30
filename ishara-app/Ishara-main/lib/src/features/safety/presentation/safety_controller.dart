import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/hardware/glasses_provider.dart';
import '../../../core/hardware/hardware_connection_service.dart';
import '../application/email_sos.dart';
import '../application/sos_coordinator.dart';
import '../data/contacts_repository.dart';

enum SafetyTab { dashboard, sos }

enum SosPhase { idle, armed, countingDown, sending, sent, cancelled }

class ObstacleReading {
  const ObstacleReading({
    required this.distanceCm,
    this.leftCm,
    this.rightCm,
    required this.timestamp,
  });

  final int distanceCm;
  final int? leftCm;
  final int? rightCm;
  final DateTime timestamp;
}

class SafetyState {
  const SafetyState({
    required this.currentTab,
    required this.obstacleReading,
    required this.sosPhase,
    required this.sosCountdownSeconds,
    required this.lastSosLocation,
    required this.error,
    required this.glassesConnected,
  });

  final SafetyTab currentTab;
  final ObstacleReading? obstacleReading;
  final SosPhase sosPhase;
  final int sosCountdownSeconds;
  final Position? lastSosLocation;
  final String? error;
  final bool glassesConnected;

  SafetyState copyWith({
    SafetyTab? currentTab,
    ObstacleReading? obstacleReading,
    SosPhase? sosPhase,
    int? sosCountdownSeconds,
    Position? lastSosLocation,
    String? error,
    bool? glassesConnected,
  }) {
    return SafetyState(
      currentTab: currentTab ?? this.currentTab,
      obstacleReading: obstacleReading ?? this.obstacleReading,
      sosPhase: sosPhase ?? this.sosPhase,
      sosCountdownSeconds: sosCountdownSeconds ?? this.sosCountdownSeconds,
      lastSosLocation: lastSosLocation ?? this.lastSosLocation,
      error: error,
      glassesConnected: glassesConnected ?? this.glassesConnected,
    );
  }

  static SafetyState get initial => SafetyState(
    currentTab: SafetyTab.dashboard,
    obstacleReading: null,
    sosPhase: SosPhase.idle,
    sosCountdownSeconds: 5,
    lastSosLocation: null,
    error: null,
    glassesConnected: false,
  );
}

class SafetyController extends StateNotifier<SafetyState> {
  SafetyController(this._hardwareService, this._ref) : super(SafetyState.initial) {
    _init();
  }

  final HardwareConnectionService _hardwareService;
  final Ref _ref;

  static const int _sosCountdownDefault = 5;
  Timer? _obstacleTimer;
  Timer? _countdownTimer;
  StreamSubscription? _sensorSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _connectionSub;

  void _init() {
    // Listen for glasses connection changes
    _connectionSub = _hardwareService.stateStream.listen((hwState) {
      final connected = hwState == HardwareConnectionState.connected;
      state = state.copyWith(glassesConnected: connected);

      if (connected) {
        // Switch to real sensor data
        _obstacleTimer?.cancel();
        _obstacleTimer = null;
        _startGlassesSensors();
      } else {
        // Fall back to simulation
        _stopGlassesSensors();
        _obstacleTimer ??= Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _simulateObstacle(),
        );
      }
    });

    // Check if already connected
    if (_hardwareService.state == HardwareConnectionState.connected) {
      state = state.copyWith(glassesConnected: true);
      _startGlassesSensors();
    } else {
      // Start simulation as default
      _obstacleTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _simulateObstacle(),
      );
    }
  }

  void _startGlassesSensors() {
    // Listen for sensor readings from glasses
    _sensorSub = _hardwareService.sensorStream.listen((data) {
      final distanceCm = data.payload?['distance_cm'] as int?;
      if (distanceCm != null && state.currentTab == SafetyTab.dashboard) {
        state = state.copyWith(
          obstacleReading: ObstacleReading(
            distanceCm: distanceCm,
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    // Listen for SOS events from glasses button
    _eventSub = _hardwareService.eventStream.listen((data) {
      final eventType = data.payload?['event'] as String?;
      if (eventType == 'sos') {
        // Auto-trigger SOS from glasses button press
        if (state.sosPhase == SosPhase.idle) {
          triggerSos();
        }
      }
    });
  }

  void _stopGlassesSensors() {
    _sensorSub?.cancel();
    _sensorSub = null;
    _eventSub?.cancel();
    _eventSub = null;
  }

  void _simulateObstacle() {
    if (state.currentTab != SafetyTab.dashboard) return;
    state = state.copyWith(
      obstacleReading: ObstacleReading(
        distanceCm: 25 + (DateTime.now().second % 40),
        leftCm: 30,
        rightCm: 28,
        timestamp: DateTime.now(),
      ),
    );
  }

  void switchTab(SafetyTab tab) {
    state = state.copyWith(currentTab: tab, error: null);
  }

  Future<bool> hasContacts() async {
    try {
      final contacts = await _ref.read(contactsRepositoryProvider).list();
      return contacts.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Single-shot SOS: pressing the button sends the email immediately.
  /// No countdown, no arming step — matches the "panic button" UX.
  Future<void> triggerSos() async {
    if (state.sosPhase == SosPhase.sending) return;
    state = state.copyWith(sosPhase: SosPhase.sending, error: null);

    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 100);
    }

    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      final contacts = _ref.read(contactsRepositoryProvider).cachedNow();
      final api = _ref.read(apiClientProvider);
      final user = _ref.read(authProvider).user;
      final coordinator = _ref.read(sosCoordinatorProvider);

      // Fire email + multi-channel (silent SMS on Android, server-routed
      // WhatsApp/Telegram via Twilio backend) in parallel.
      final results = await Future.wait([
        EmailSos.dispatch(
          api: api,
          contacts: contacts,
          senderName: user?.name ?? 'Ishara user',
          senderPhone: '',
          location: pos,
        ),
        coordinator.dispatch(),
      ]);
      final emailResult = results[0] as EmailSosResult;
      final coordResult = results[1] as SosDispatchResult;
      final anyOk = emailResult.success || coordResult.success;
      final err = anyOk
          ? null
          : (emailResult.error ??
              (coordResult.errors.isEmpty
                  ? 'Could not deliver SOS through any channel.'
                  : coordResult.errors.first));

      state = state.copyWith(
        sosPhase: SosPhase.sent,
        lastSosLocation: pos,
        error: err,
      );

      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (e) {
      state = state.copyWith(sosPhase: SosPhase.idle, error: e.toString());
    }
  }

  void resetSos() {
    state = state.copyWith(
      sosPhase: SosPhase.idle,
      sosCountdownSeconds: _sosCountdownDefault,
      error: null,
    );
  }

  @override
  void dispose() {
    _obstacleTimer?.cancel();
    _countdownTimer?.cancel();
    _sensorSub?.cancel();
    _eventSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }
}

final safetyControllerProvider =
    StateNotifierProvider<SafetyController, SafetyState>((ref) {
      final hw = ref.watch(hardwareServiceProvider);
      return SafetyController(hw, ref);
    });
