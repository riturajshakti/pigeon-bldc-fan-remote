import 'protocol.dart';

class FanCommand {
  const FanCommand(this.label, this.code);
  final String label;
  final int code;
}

class FanProfile {
  const FanProfile({
    required this.name,
    required this.protocol,
    required this.address,
    required this.light,
    required this.power,
    required this.timer,
    required this.reverse,
    required this.sleep,
    required this.boost,
    required this.minus,
    required this.plus,
  });

  final String name;
  final IrProtocol protocol;
  final int address;
  final FanCommand light;
  final FanCommand power;
  final FanCommand timer;
  final FanCommand reverse;
  final FanCommand sleep;
  final FanCommand boost;
  final FanCommand minus;
  final FanCommand plus;
}

const pigeonBldcProfile = FanProfile(
  name: 'Pigeon BLDC Fan',
  protocol: necProtocol,
  address: 0,
  light: FanCommand('Light', 140),
  power: FanCommand('Power', 129),
  timer: FanCommand('Timer', 150),
  reverse: FanCommand('Reverse', 136),
  sleep: FanCommand('Sleep', 135),
  boost: FanCommand('Boost', 142),
  minus: FanCommand('Minus', 146),
  plus: FanCommand('Plus', 149),
);

const minSpeed = 1;
const maxSpeed = 5;
