import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_fan_remote/app_info.dart';
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
  for (final size in const [Size(360, 640), Size(393, 873)]) {
    testWidgets('about dialog shows all fields at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = FanController(FakeIr(), pigeonBldcProfile);
      await controller.init();

      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: HomeScreen(controller: controller),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('About'));
      await tester.pumpAndSettle();

      expect(find.text(AppInfo.author), findsOneWidget);
      expect(find.text(AppInfo.email), findsOneWidget);
      expect(find.text(AppInfo.version), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppInfo.versionCode),
        ),
        findsOneWidget,
      );
      expect(find.text('Email'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
