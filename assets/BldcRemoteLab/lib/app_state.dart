import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ir_service.dart';
import 'protocol.dart';

const fanButtons = <String>[
  'Power',
  'Speed +',
  'Speed -',
  'Boost',
  'Reverse',
  'Sleep',
  'Timer',
  'Sun / Light',
];

enum SweepMark { untested, noEffect, didSomething, identified }

class AppState extends ChangeNotifier {
  AppState(this._ir);

  final IrService _ir;

  IrCapabilities? capabilities;
  String? lastError;

  IrProtocol protocol = protocols.first;
  int address = 0;
  int repeats = 1;
  int? carrierOverride;

  final Map<String, int?> buttonCodes = {for (final b in fanButtons) b: null};
  final Map<int, SweepMark> sweepMarks = {};
  final Map<int, String> sweepNotes = {};

  int get frequency => carrierOverride ?? protocol.frequency;

  Future<void> init() async {
    capabilities = await _ir.probe();
    await _load();
    notifyListeners();
  }

  Future<void> send(int command) async {
    lastError = null;
    final pattern = protocol.encode(address: address, command: command);
    try {
      for (var i = 0; i < repeats; i++) {
        await _ir.transmit(frequency: frequency, pattern: pattern);
      }
    } on PlatformException catch (e) {
      lastError = '${e.code}: ${e.message}';
    } catch (e) {
      lastError = e.toString();
    }
    notifyListeners();
  }

  void setProtocol(IrProtocol p) {
    protocol = p;
    _persist();
    notifyListeners();
  }

  void setAddress(int value) {
    address = value & 0xFFFF;
    _persist();
    notifyListeners();
  }

  void setRepeats(int value) {
    repeats = value.clamp(1, 10);
    _persist();
    notifyListeners();
  }

  void setCarrierOverride(int? value) {
    carrierOverride = value;
    _persist();
    notifyListeners();
  }

  void setButtonCode(String button, int? code) {
    buttonCodes[button] = code;
    _persist();
    notifyListeners();
  }

  void markSweep(int code, SweepMark mark) {
    sweepMarks[code] = mark;
    _persist();
    notifyListeners();
  }

  void noteSweep(int code, String note) {
    if (note.isEmpty) {
      sweepNotes.remove(code);
    } else {
      sweepNotes[code] = note;
    }
    _persist();
    notifyListeners();
  }

  void clearSweep() {
    sweepMarks.clear();
    sweepNotes.clear();
    _persist();
    notifyListeners();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'device': 'Pigeon BLDC Fan',
        'protocol': protocol.name,
        'carrierFrequency': frequency,
        'address': address,
        'repeats': repeats,
        'buttons': {
          for (final e in buttonCodes.entries)
            if (e.value != null) e.key: e.value,
        },
        'sweep': {
          for (final e in sweepMarks.entries)
            if (e.value != SweepMark.untested)
              '${e.key}': {
                'result': e.value.name,
                if (sweepNotes[e.key] != null) 'note': sweepNotes[e.key],
              },
        },
      });

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('state');
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;

    final protocolName = map['protocol'] as String?;
    protocol = protocols.firstWhere(
      (p) => p.name == protocolName,
      orElse: () => protocols.first,
    );
    address = map['address'] as int? ?? 0;
    repeats = map['repeats'] as int? ?? 1;
    carrierOverride = map['carrierOverride'] as int?;

    final codes = map['buttonCodes'] as Map<String, dynamic>? ?? {};
    for (final b in fanButtons) {
      buttonCodes[b] = codes[b] as int?;
    }

    final marks = map['sweepMarks'] as Map<String, dynamic>? ?? {};
    marks.forEach((k, v) {
      final code = int.tryParse(k);
      if (code == null) return;
      sweepMarks[code] = SweepMark.values.firstWhere(
        (m) => m.name == v,
        orElse: () => SweepMark.untested,
      );
    });

    final notes = map['sweepNotes'] as Map<String, dynamic>? ?? {};
    notes.forEach((k, v) {
      final code = int.tryParse(k);
      if (code != null) sweepNotes[code] = v as String;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'state',
      jsonEncode({
        'protocol': protocol.name,
        'address': address,
        'repeats': repeats,
        'carrierOverride': carrierOverride,
        'buttonCodes': buttonCodes,
        'sweepMarks': {
          for (final e in sweepMarks.entries) '${e.key}': e.value.name,
        },
        'sweepNotes': {
          for (final e in sweepNotes.entries) '${e.key}': e.value,
        },
      }),
    );
  }
}
