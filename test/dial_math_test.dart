import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_fan_remote/fan_controller.dart';
import 'package:pigeon_fan_remote/fan_profile.dart';
import 'package:pigeon_fan_remote/home_screen.dart';
import 'package:pigeon_fan_remote/ir_service.dart';
import 'package:pigeon_fan_remote/theme.dart';

class FakeIr extends IrService {
  final List<int> sent = [];
  @override
  Future<IrCapabilities> probe() async =>
      const IrCapabilities(hasEmitter: true, carrierRanges: []);
  @override
  Future<void> transmit({required int frequency, required List<int> pattern}) async {
    sent.add(pattern.length);
  }
  @override
  Future<Map<String, Object?>> loadPrefs() async => {};
  @override
  Future<void> savePrefs({int? speed, String? theme, bool? boostOn}) async {}
}

const dialStart = math.pi * 0.75;
const dialSweep = math.pi * 1.5;

int? levelFromOffset(Offset local, Size dial) {
  final center = Offset(dial.width / 2, dial.height / 2);
  final v = local - center;
  if (v.distance < dial.width * 0.21) return null;

  final raw = math.atan2(v.dy, v.dx);
  var off = (raw - dialStart) % (2 * math.pi);
  if (off < 0) off += 2 * math.pi;

  if (off > dialSweep) {
    final past = off - dialSweep;
    return past < (2 * math.pi - dialSweep) / 2 ? maxSpeed : minSpeed;
  }

  final fraction = off / dialSweep;
  return (minSpeed + (fraction * (maxSpeed - minSpeed)).round())
      .clamp(minSpeed, maxSpeed);
}

void main() {
  const size = Size(400, 400);
  const radius = 400 * 0.36;

  Offset pointAt(double angle) => Offset(
        200 + math.cos(angle) * radius,
        200 + math.sin(angle) * radius,
      );

  test('each node position maps to its own level', () {
    for (var i = minSpeed; i <= maxSpeed; i++) {
      final angle =
          dialStart + dialSweep * (i - minSpeed) / (maxSpeed - minSpeed);
      expect(levelFromOffset(pointAt(angle), size), i,
          reason: 'node $i at ${angle * 180 / math.pi}deg');
    }
  });

  test('centre dead zone returns null', () {
    expect(levelFromOffset(const Offset(200, 200), size), isNull);
    expect(levelFromOffset(const Offset(210, 205), size), isNull);
  });

  test('bottom gap snaps to the nearer end', () {
    expect(levelFromOffset(pointAt(math.pi / 2 - 0.3), size), maxSpeed);
    expect(levelFromOffset(pointAt(math.pi / 2 + 0.3), size), minSpeed);
  });

  testWidgets('dragging the arc sets the speed', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = FanController(FakeIr(), pigeonBldcProfile);
    await controller.init();

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: HomeScreen(controller: controller),
    ));
    await tester.pumpAndSettle();

    final dial = find.byType(SpeedDial);
    final box = tester.getRect(dial);
    final c = box.center;
    final r = math.min(box.width, box.height) * 0.36;

    final node3 = Offset(
      c.dx + math.cos(dialStart + dialSweep * 0.5) * r,
      c.dy + math.sin(dialStart + dialSweep * 0.5) * r,
    );
    final midArc = Offset(
      c.dx + math.cos(dialStart + dialSweep * 0.25) * r,
      c.dy + math.sin(dialStart + dialSweep * 0.25) * r,
    );

    final gesture = await tester.startGesture(midArc);
    await tester.pump();
    await gesture.moveTo(node3);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(controller.speed, 3);
  });

  testWidgets('tapping a node still works through the drag layer',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = FanController(FakeIr(), pigeonBldcProfile);
    await controller.init();

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: HomeScreen(controller: controller),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(controller.speed, 4);
  });

  testWidgets('power node is tappable, not a drag target', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ir = FakeIr();
    final controller = FanController(ir, pigeonBldcProfile);
    await controller.init();

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: HomeScreen(controller: controller),
    ));
    await tester.pumpAndSettle();

    final before = controller.speed;
    await tester.tap(find.descendant(
      of: find.byType(SpeedDial),
      matching: find.bySemanticsLabel('Power'),
    ).first);
    await tester.pumpAndSettle();

    expect(controller.speed, before);
    expect(ir.sent, isNotEmpty);
  });
}
