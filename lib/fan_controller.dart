import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'fan_profile.dart';
import 'ir_service.dart';

enum ThemeChoice { system, light, dark }

const _stepGap = Duration(milliseconds: 1);

class FanController extends ChangeNotifier {
  FanController(this._ir, this.profile);

  final IrService _ir;
  final FanProfile profile;

  bool hasEmitter = true;
  String? lastError;
  String? lastAction;
  int speed = minSpeed;
  bool busy = false;
  bool boostOn = false;
  ThemeChoice theme = ThemeChoice.system;

  Future<void> init() async {
    final caps = await _ir.probe();
    hasEmitter = caps.hasEmitter;
    final prefs = await _ir.loadPrefs();
    final storedSpeed = prefs['speed'] as int? ?? -1;
    speed = storedSpeed < minSpeed ? minSpeed : storedSpeed.clamp(minSpeed, maxSpeed);
    boostOn = prefs['boostOn'] as bool? ?? false;
    theme = ThemeChoice.values.firstWhere(
      (t) => t.name == prefs['theme'],
      orElse: () => ThemeChoice.system,
    );
    notifyListeners();
  }

  Future<void> setTheme(ThemeChoice choice) async {
    theme = choice;
    notifyListeners();
    await _ir.savePrefs(theme: choice.name);
  }

  Future<void> send(FanCommand command) async {
    await _sendRaw(command.code);
    lastAction = command.label;
    notifyListeners();
  }

  Future<void> toggleBoost() async {
    if (busy) return;
    await _sendRaw(profile.boost.code);
    if (lastError == null) {
      boostOn = true;
      await _ir.savePrefs(boostOn: true);
    }
    lastAction = profile.boost.label;
    notifyListeners();
  }

  Future<void> nudge(FanCommand command, {required int delta}) async {
    if (busy) return;
    await _sendRaw(command.code);
    if (lastError == null) {
      if (delta < 0 && boostOn) {
        boostOn = false;
        _setSpeed(maxSpeed);
      } else if (!boostOn) {
        _setSpeed((speed + delta).clamp(minSpeed, maxSpeed));
      }
    }
    lastAction = command.label;
    notifyListeners();
  }

  Future<void> selectSpeed(int target) async {
    if (busy) return;
    final clamped = target.clamp(minSpeed, maxSpeed);

    busy = true;
    lastAction = 'Speed $clamped';
    notifyListeners();

    for (var i = 0; i < maxSpeed; i++) {
      await _sendRaw(profile.minus.code);
      if (lastError != null) {
        busy = false;
        notifyListeners();
        return;
      }
      await Future<void>.delayed(_stepGap);
    }
    boostOn = false;
    _setSpeed(minSpeed);
    notifyListeners();

    for (var i = minSpeed; i < clamped; i++) {
      await _sendRaw(profile.plus.code);
      if (lastError != null) break;
      _setSpeed(speed + 1);
      notifyListeners();
      await Future<void>.delayed(_stepGap);
    }

    busy = false;
    notifyListeners();
  }

  Future<void> resyncToMinimum() async {
    if (busy) return;
    busy = true;
    boostOn = false;
    lastAction = 'Resync to speed $minSpeed';
    notifyListeners();

    for (var i = 0; i < maxSpeed; i++) {
      await _sendRaw(profile.minus.code);
      if (lastError != null) break;
      await Future<void>.delayed(_stepGap);
    }
    _setSpeed(minSpeed);

    busy = false;
    notifyListeners();
  }

  Future<void> _sendRaw(int code) async {
    lastError = null;
    final pattern = profile.protocol.encode(
      address: profile.address,
      command: code,
    );
    try {
      await _ir.transmit(
        frequency: profile.protocol.frequency,
        pattern: pattern,
      );
    } on PlatformException catch (e) {
      lastError = e.message ?? e.code;
    } catch (e) {
      lastError = e.toString();
    }
  }

  void _setSpeed(int value) {
    speed = value;
    _ir.savePrefs(speed: value, boostOn: boostOn);
  }
}
