import 'package:flutter_test/flutter_test.dart';
import 'package:pigeon_fan_remote/protocol.dart';

void main() {
  test('NEC frame has header, 32 bits, trailer and gap', () {
    final pattern = necProtocol.encode(address: 0, command: 8);
    expect(pattern.length, 2 + 32 * 2 + 2);
    expect(pattern[0], 9000);
    expect(pattern[1], 4500);
    expect(pattern.every((d) => d > 0), isTrue);
  });

  test('NEC sends command LSB first with inverted copy', () {
    final pattern = necProtocol.encode(address: 0, command: 8);
    final spaces = [
      for (var i = 3; i < pattern.length - 2; i += 2) pattern[i],
    ];
    final bits = spaces.map((s) => s == necProtocol.oneSpace ? 1 : 0).toList();

    expect(bits.sublist(0, 8), List.filled(8, 0));
    expect(bits.sublist(8, 16), List.filled(8, 1));
    expect(bits.sublist(16, 24), [0, 0, 0, 1, 0, 0, 0, 0]);
    expect(bits.sublist(24, 32), [1, 1, 1, 0, 1, 1, 1, 1]);
  });

  test('no-invert variant emits half the bits', () {
    final pattern = nec8BitNoInvertProtocol.encode(address: 0, command: 8);
    expect(pattern.length, 2 + 16 * 2 + 2);
  });
}
