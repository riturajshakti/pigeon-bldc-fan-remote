import 'package:flutter/services.dart';

class CarrierRange {
  const CarrierRange(this.min, this.max);
  final int min;
  final int max;

  @override
  String toString() => min == max ? '$min Hz' : '$min–$max Hz';
}

class IrCapabilities {
  const IrCapabilities({required this.hasEmitter, required this.carrierRanges});
  final bool hasEmitter;
  final List<CarrierRange> carrierRanges;
}

class IrService {
  static const _channel = MethodChannel('com.raj.pigeon_fan_remote/ir');

  Future<IrCapabilities> probe() async {
    final hasEmitter = await _channel.invokeMethod<bool>('hasIrEmitter') ?? false;
    if (!hasEmitter) {
      return const IrCapabilities(hasEmitter: false, carrierRanges: []);
    }
    final raw = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getCarrierFrequencies');
    final ranges = (raw ?? [])
        .map((e) => CarrierRange(e['min'] as int, e['max'] as int))
        .toList();
    return IrCapabilities(hasEmitter: true, carrierRanges: ranges);
  }

  Future<void> transmit({required int frequency, required List<int> pattern}) {
    return _channel.invokeMethod('transmit', {
      'frequency': frequency,
      'pattern': pattern,
    });
  }

  Future<Map<String, Object?>> loadPrefs() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('loadPrefs');
    return raw ?? {};
  }

  Future<void> savePrefs({int? speed, String? theme, bool? boostOn}) {
    return _channel.invokeMethod('savePrefs', {
      'speed': ?speed,
      'theme': ?theme,
      'boostOn': ?boostOn,
    });
  }
}
