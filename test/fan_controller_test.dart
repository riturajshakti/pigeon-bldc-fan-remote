import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_fan_remote/fan_controller.dart';
import 'package:pigeon_fan_remote/fan_profile.dart';
import 'package:pigeon_fan_remote/ir_service.dart';
import 'package:pigeon_fan_remote/protocol.dart';

class RecordingIrService extends IrService {
  final List<int> sentCommands = [];
  final Map<String, Object?> stored = {};

  @override
  Future<Map<String, Object?>> loadPrefs() async => stored;

  @override
  Future<void> savePrefs({int? speed, String? theme, bool? boostOn}) async {
    if (speed != null) stored['speed'] = speed;
    if (theme != null) stored['theme'] = theme;
    if (boostOn != null) stored['boostOn'] = boostOn;
  }

  @override
  Future<IrCapabilities> probe() async =>
      const IrCapabilities(hasEmitter: true, carrierRanges: []);

  @override
  Future<void> transmit({required int frequency, required List<int> pattern}) async {
    final spaces = [for (var i = 3; i < pattern.length - 2; i += 2) pattern[i]];
    final bits = spaces.map((s) => s == necProtocol.oneSpace ? 1 : 0).toList();
    var command = 0;
    for (var i = 0; i < 8; i++) {
      command |= bits[16 + i] << i;
    }
    sentCommands.add(command);
  }
}

void main() {
  Future<FanController> freshController(RecordingIrService ir) async {
    final controller = FanController(ir, pigeonBldcProfile);
    await controller.init();
    return controller;
  }

  test('selectSpeed floors to minimum then counts up', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.selectSpeed(4);

    expect(ir.sentCommands, [
      ...List.filled(maxSpeed, pigeonBldcProfile.minus.code),
      ...List.filled(3, pigeonBldcProfile.plus.code),
    ]);
    expect(controller.speed, 4);
  });

  test('selectSpeed is absolute regardless of prior speed', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.selectSpeed(5);
    ir.sentCommands.clear();

    await controller.selectSpeed(2);

    expect(ir.sentCommands, [
      ...List.filled(maxSpeed, pigeonBldcProfile.minus.code),
      pigeonBldcProfile.plus.code,
    ]);
    expect(controller.speed, 2);
  });

  test('selecting speed 1 floors the fan', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.selectSpeed(1);

    expect(ir.sentCommands, List.filled(maxSpeed, pigeonBldcProfile.minus.code));
    expect(controller.speed, 1);
  });

  test('selectSpeed clamps to the supported range', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.selectSpeed(99);

    expect(controller.speed, maxSpeed);
    expect(ir.sentCommands.length, maxSpeed + (maxSpeed - minSpeed));
  });

  test('resync floors the fan and lands on minimum', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.selectSpeed(3);
    ir.sentCommands.clear();

    await controller.resyncToMinimum();

    expect(ir.sentCommands, List.filled(maxSpeed, pigeonBldcProfile.minus.code));
    expect(controller.speed, minSpeed);
  });

  test('nudge tracks speed alongside the raw command', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.nudge(pigeonBldcProfile.plus, delta: 1);
    await controller.nudge(pigeonBldcProfile.plus, delta: 1);

    expect(ir.sentCommands, [pigeonBldcProfile.plus.code, pigeonBldcProfile.plus.code]);
    expect(controller.speed, minSpeed + 2);
  });

  test('nudge does not run past the ends of the range', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.nudge(pigeonBldcProfile.minus, delta: -1);

    expect(controller.speed, minSpeed);
  });


  test('every boost press transmits, and boost never self-cancels', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);

    await controller.toggleBoost();
    expect(controller.boostOn, isTrue);

    await controller.toggleBoost();
    await controller.toggleBoost();

    expect(controller.boostOn, isTrue);
    expect(ir.sentCommands, List.filled(3, pigeonBldcProfile.boost.code));
  });

  test('speed minus exits boost and lands at max', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.toggleBoost();
    ir.sentCommands.clear();

    await controller.nudge(pigeonBldcProfile.minus, delta: -1);

    expect(controller.boostOn, isFalse);
    expect(controller.speed, maxSpeed);
    expect(ir.sentCommands, [pigeonBldcProfile.minus.code]);
  });

  test('speed plus while boosted does not change the model', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.toggleBoost();
    final before = controller.speed;

    await controller.nudge(pigeonBldcProfile.plus, delta: 1);

    expect(controller.boostOn, isTrue);
    expect(controller.speed, before);
  });

  test('changing speed clears boost', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.toggleBoost();

    await controller.selectSpeed(3);

    expect(controller.boostOn, isFalse);
    expect(controller.speed, 3);
  });

  test('resync clears boost', () async {
    final ir = RecordingIrService();
    final controller = await freshController(ir);
    await controller.toggleBoost();

    await controller.resyncToMinimum();

    expect(controller.boostOn, isFalse);
    expect(controller.speed, minSpeed);
  });

  test('profile carries the verified sweep codes', () {
    expect(pigeonBldcProfile.power.code, 129);
    expect(pigeonBldcProfile.sleep.code, 135);
    expect(pigeonBldcProfile.reverse.code, 136);
    expect(pigeonBldcProfile.light.code, 140);
    expect(pigeonBldcProfile.boost.code, 142);
    expect(pigeonBldcProfile.minus.code, 146);
    expect(pigeonBldcProfile.plus.code, 149);
    expect(pigeonBldcProfile.timer.code, 150);
  });
}
