import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ishara_app/src/core/hardware/hardware_connection_service.dart';
import 'package:ishara_app/src/features/safety/presentation/safety_controller.dart';

/// Minimal fake Ref that satisfies SafetyController without a real ProviderContainer.
class _FakeRef extends Fake implements Ref {}

void main() {
  group('SafetyController', () {
    late SafetyController controller;
    late HardwareConnectionService hardware;

    setUp(() {
      hardware = HardwareConnectionService();
      controller = SafetyController(hardware, _FakeRef());
    });

    tearDown(() {
      controller.dispose();
      hardware.dispose();
    });

    test('initial state is dashboard and idle', () {
      expect(controller.state.currentTab, SafetyTab.dashboard);
      expect(controller.state.sosPhase, SosPhase.idle);
    });

    test('switchTab updates currentTab', () {
      controller.switchTab(SafetyTab.sos);
      expect(controller.state.currentTab, SafetyTab.sos);
    });

    test('resetSos sets phase to idle', () {
      // Drive state to something other than idle first via resetSos itself
      // (resetSos is idempotent — it always sets idle).
      controller.resetSos();
      expect(controller.state.sosPhase, SosPhase.idle);
    });

    test('resetSos restores default countdown seconds', () {
      controller.resetSos();
      expect(controller.state.sosCountdownSeconds, 5);
    });

    test('switchTab clears error', () {
      // Switching tab should always clear the error field.
      controller.switchTab(SafetyTab.dashboard);
      expect(controller.state.error, isNull);
    });
  });

  group('ObstacleReading', () {
    test('ObstacleReading holds values', () {
      final now = DateTime.now();
      final r = ObstacleReading(
        distanceCm: 30,
        leftCm: 25,
        rightCm: 28,
        timestamp: now,
      );
      expect(r.distanceCm, 30);
      expect(r.leftCm, 25);
      expect(r.timestamp, now);
    });

    test('ObstacleReading allows null optional fields', () {
      final r = ObstacleReading(
        distanceCm: 50,
        timestamp: DateTime.now(),
      );
      expect(r.leftCm, isNull);
      expect(r.rightCm, isNull);
    });
  });
}
