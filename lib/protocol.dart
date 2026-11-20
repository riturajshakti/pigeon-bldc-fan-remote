class IrProtocol {
  const IrProtocol({
    required this.name,
    required this.frequency,
    required this.headerMark,
    required this.headerSpace,
    required this.bitMark,
    required this.oneSpace,
    required this.zeroSpace,
    required this.trailerMark,
    required this.gap,
    required this.addressBits,
    required this.commandBits,
    required this.sendInvertedAddress,
    required this.sendInvertedCommand,
    required this.lsbFirst,
  });

  final String name;
  final int frequency;
  final int headerMark;
  final int headerSpace;
  final int bitMark;
  final int oneSpace;
  final int zeroSpace;
  final int trailerMark;
  final int gap;
  final int addressBits;
  final int commandBits;
  final bool sendInvertedAddress;
  final bool sendInvertedCommand;
  final bool lsbFirst;

  IrProtocol copyWith({int? frequency}) => IrProtocol(
        name: name,
        frequency: frequency ?? this.frequency,
        headerMark: headerMark,
        headerSpace: headerSpace,
        bitMark: bitMark,
        oneSpace: oneSpace,
        zeroSpace: zeroSpace,
        trailerMark: trailerMark,
        gap: gap,
        addressBits: addressBits,
        commandBits: commandBits,
        sendInvertedAddress: sendInvertedAddress,
        sendInvertedCommand: sendInvertedCommand,
        lsbFirst: lsbFirst,
      );

  List<int> encode({required int address, required int command}) {
    final bits = <int>[];
    _appendByte(bits, address, addressBits);
    if (sendInvertedAddress) _appendByte(bits, ~address & 0xFF, addressBits);
    _appendByte(bits, command, commandBits);
    if (sendInvertedCommand) _appendByte(bits, ~command & 0xFF, commandBits);

    final pattern = <int>[headerMark, headerSpace];
    for (final bit in bits) {
      pattern.add(bitMark);
      pattern.add(bit == 1 ? oneSpace : zeroSpace);
    }
    if (trailerMark > 0) pattern.add(trailerMark);
    pattern.add(gap);
    return pattern;
  }

  void _appendByte(List<int> out, int value, int width) {
    for (var i = 0; i < width; i++) {
      final shift = lsbFirst ? i : width - 1 - i;
      out.add((value >> shift) & 1);
    }
  }
}

const necProtocol = IrProtocol(
  name: 'NEC',
  frequency: 38000,
  headerMark: 9000,
  headerSpace: 4500,
  bitMark: 560,
  oneSpace: 1690,
  zeroSpace: 560,
  trailerMark: 560,
  gap: 40000,
  addressBits: 8,
  commandBits: 8,
  sendInvertedAddress: true,
  sendInvertedCommand: true,
  lsbFirst: true,
);

const necExtendedProtocol = IrProtocol(
  name: 'NEC extended (16-bit addr)',
  frequency: 38000,
  headerMark: 9000,
  headerSpace: 4500,
  bitMark: 560,
  oneSpace: 1690,
  zeroSpace: 560,
  trailerMark: 560,
  gap: 40000,
  addressBits: 16,
  commandBits: 8,
  sendInvertedAddress: false,
  sendInvertedCommand: true,
  lsbFirst: true,
);

const nec8BitNoInvertProtocol = IrProtocol(
  name: 'NEC frame, no inverted bytes',
  frequency: 38000,
  headerMark: 9000,
  headerSpace: 4500,
  bitMark: 560,
  oneSpace: 1690,
  zeroSpace: 560,
  trailerMark: 560,
  gap: 40000,
  addressBits: 8,
  commandBits: 8,
  sendInvertedAddress: false,
  sendInvertedCommand: false,
  lsbFirst: true,
);

const protocols = <IrProtocol>[
  necProtocol,
  necExtendedProtocol,
  nec8BitNoInvertProtocol,
];
