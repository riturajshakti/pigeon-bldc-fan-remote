import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_fan_remote/fan_controller.dart';
import 'package:pigeon_fan_remote/fan_profile.dart';
import 'package:pigeon_fan_remote/home_screen.dart';
import 'package:pigeon_fan_remote/ir_service.dart';
import 'package:pigeon_fan_remote/theme.dart';

class FakeIr extends IrService {
  @override
  Future<IrCapabilities> probe() async =>
      const IrCapabilities(hasEmitter: true, carrierRanges: []);
  @override
  Future<void> transmit({required int frequency, required List<int> pattern}) async {}
  @override
  Future<Map<String, Object?>> loadPrefs() async => {};
  @override
  Future<void> savePrefs({int? speed, String? theme, bool? boostOn}) async {}
}

void main() {
  const sizes = <String, Size>{
    'small phone 360x640': Size(360, 640),
    'poco x6 393x873': Size(393, 873),
    'tall 412x915': Size(412, 915),
    'short 360x600': Size(360, 600),
    'tablet 800x1280': Size(800, 1280),
  };

  for (final entry in sizes.entries) {
    testWidgets('fits without overflow: ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = FanController(FakeIr(), pigeonBldcProfile);
      await controller.init();

      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: HomeScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BOOST'), findsOneWidget);
      expect(find.text('Resync'), findsOneWidget);
      for (var i = 1; i <= 5; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });
  }

  testWidgets('tapping a speed node drives the fan', (tester) async {
    tester.view.physicalSize = const Size(393, 873);
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
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(controller.speed, 4);
  });
}
