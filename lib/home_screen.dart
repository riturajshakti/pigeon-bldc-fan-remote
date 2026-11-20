import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'app_info.dart';
import 'fan_controller.dart';
import 'fan_profile.dart';
import 'theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final FanController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = (constraints.maxHeight * 0.016).clamp(8.0, 14.0);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gap, gap * 1.2, gap, gap),
                  child: Column(
                    children: [
                      _Header(controller: controller),
                      SizedBox(height: gap),
                      _ButtonGrid(controller: controller, gap: gap),
                      SizedBox(height: gap),
                      Expanded(child: SpeedDial(controller: controller)),
                      SizedBox(height: gap),
                      _StatusBar(controller: controller),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final FanController controller;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    return Row(
      children: [
        Expanded(
          child: Text(
            controller.profile.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: fan.onSurface,
            ),
          ),
        ),
        _CircleIconButton(
          icon: controller.theme == ThemeChoice.light
              ? Symbols.light_mode_rounded
              : controller.theme == ThemeChoice.dark
                  ? Symbols.dark_mode_rounded
                  : Symbols.contrast_rounded,
          tooltip: 'Theme',
          onTap: () {
            const order = [
              ThemeChoice.system,
              ThemeChoice.light,
              ThemeChoice.dark,
            ];
            final next = order[(order.indexOf(controller.theme) + 1) % 3];
            controller.setTheme(next);
          },
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Symbols.info_rounded,
          tooltip: 'About',
          onTap: () => showAboutDialogForApp(context),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: fan.surface,
        shape: CircleBorder(side: BorderSide(color: fan.outline)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: fan.onSurface),
          ),
        ),
      ),
    );
  }
}

class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid({required this.controller, required this.gap});

  final FanController controller;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final p = controller.profile;
    final tiles = <Widget>[
      _Tile(
        controller: controller,
        label: 'Power',
        icon: Symbols.power_settings_new_rounded,
        style: _TileStyle.power,
        onTap: () => controller.send(p.power),
      ),
      _Tile(
        controller: controller,
        label: 'Light',
        icon: Symbols.light_mode_rounded,
        onTap: () => controller.send(p.light),
      ),
      _Tile(
        controller: controller,
        label: 'Timer',
        icon: Symbols.timer_rounded,
        onTap: () => controller.send(p.timer),
      ),
      _Tile(
        controller: controller,
        label: 'Reverse',
        icon: Symbols.rotate_left_rounded,
        onTap: () => controller.send(p.reverse),
      ),
      _Tile(
        controller: controller,
        label: 'Sleep',
        icon: Symbols.bedtime_rounded,
        onTap: () => controller.send(p.sleep),
      ),
      _Tile(
        controller: controller,
        label: 'Speed −',
        icon: Symbols.remove_rounded,
        onTap: () => controller.nudge(p.minus, delta: -1),
      ),
      _Tile(
        controller: controller,
        label: 'Speed +',
        icon: Symbols.add_rounded,
        onTap: () => controller.nudge(p.plus, delta: 1),
      ),
      _Tile(
        controller: controller,
        label: 'Boost',
        icon: Symbols.bolt_rounded,
        style: controller.boostOn ? _TileStyle.active : _TileStyle.normal,
        onTap: controller.toggleBoost,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      children: tiles,
    );
  }
}

enum _TileStyle { normal, power, active }

class _Tile extends StatelessWidget {
  const _Tile({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onTap,
    this.style = _TileStyle.normal,
  });

  final FanController controller;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final _TileStyle style;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    final (bg, border, fg) = switch (style) {
      _TileStyle.power => (fan.surfaceHi, fan.accent, fan.accent),
      _TileStyle.active => (fan.surfaceHi, fan.accent, fan.accent),
      _TileStyle.normal => (fan.surface, fan.outline, fan.onSurface),
    };
    final bold = style != _TileStyle.normal;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: controller.busy
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: bold ? 1.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: fg,
                fill: bold ? 1 : 0,
                weight: bold ? 700 : 400,
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _dialStart = math.pi * 0.75;
const _dialSweep = math.pi * 1.5;

class SpeedDial extends StatefulWidget {
  const SpeedDial({super.key, required this.controller});

  final FanController controller;

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial> {
  int? _dragLevel;
  Size _dialSize = Size.zero;

  int? _levelFromOffset(Offset local) {
    final center = Offset(_dialSize.width / 2, _dialSize.height / 2);
    final v = local - center;
    if (v.distance < _dialSize.width * 0.21) return null;

    final raw = math.atan2(v.dy, v.dx);
    var off = (raw - _dialStart) % (2 * math.pi);
    if (off < 0) off += 2 * math.pi;

    if (off > _dialSweep) {
      final past = off - _dialSweep;
      return past < (2 * math.pi - _dialSweep) / 2 ? maxSpeed : minSpeed;
    }

    final fraction = off / _dialSweep;
    return (minSpeed + (fraction * (maxSpeed - minSpeed)).round())
        .clamp(minSpeed, maxSpeed);
  }

  void _onDragUpdate(Offset local) {
    final level = _levelFromOffset(local);
    if (level != null && level != _dragLevel) {
      HapticFeedback.selectionClick();
      setState(() => _dragLevel = level);
    }
  }

  void _commit() {
    final target = _dragLevel;
    setState(() => _dragLevel = null);
    if (target != null) widget.controller.selectSpeed(target);
  }

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    final controller = widget.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        _dialSize = Size.square(size);

        final nodeSize = size * 0.19;
        final radius = size * 0.36;
        final level =
            _dragLevel ?? (controller.boostOn ? maxSpeed : controller.speed);

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArcPainter(
                      fraction: (level - minSpeed) / (maxSpeed - minSpeed),
                      radius: radius,
                      track: fan.surfaceHi,
                      active: fan.accent,
                      stroke: size * 0.05,
                    ),
                  ),
                ),
                for (var i = minSpeed; i <= maxSpeed; i++)
                  Transform.translate(
                    offset: _offsetFor(
                      _dialStart +
                          _dialSweep * (i - minSpeed) / (maxSpeed - minSpeed),
                      radius,
                    ),
                    child: _SpeedNode(
                      controller: controller,
                      level: i,
                      size: nodeSize,
                      on: i <= level,
                    ),
                  ),
                Transform.translate(
                  offset: _offsetFor(math.pi / 2, radius),
                  child: _PowerNode(controller: controller, size: nodeSize),
                ),
                _BoostButton(controller: controller, dialSize: size),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: controller.busy
                        ? null
                        : (d) => _onDragUpdate(d.localPosition),
                    onPanUpdate: controller.busy
                        ? null
                        : (d) => _onDragUpdate(d.localPosition),
                    onPanEnd: controller.busy ? null : (_) => _commit(),
                    onPanCancel: () => setState(() => _dragLevel = null),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _offsetFor(double angle, double radius) =>
      Offset(math.cos(angle) * radius, math.sin(angle) * radius);
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.fraction,
    required this.radius,
    required this.track,
    required this.active,
    required this.stroke,
  });

  final double fraction;
  final double radius;
  final Color track;
  final Color active;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, _dialStart, _dialSweep, false, base);

    if (fraction > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = active;
      canvas.drawArc(rect, _dialStart, _dialSweep * fraction, false, progress);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction ||
      old.radius != radius ||
      old.track != track ||
      old.active != active ||
      old.stroke != stroke;
}

class _SpeedNode extends StatelessWidget {
  const _SpeedNode({
    required this.controller,
    required this.level,
    required this.size,
    required this.on,
  });

  final FanController controller;
  final int level;
  final double size;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    return Semantics(
      button: true,
      selected: on,
      label: 'Speed $level',
      child: Material(
        color: on ? fan.accent : fan.surfaceHi,
        shape: CircleBorder(
          side: BorderSide(color: on ? fan.accent : fan.outline, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: controller.busy
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  controller.selectSpeed(level);
                },
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  color: on ? fan.onAccent : fan.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerNode extends StatelessWidget {
  const _PowerNode({required this.controller, required this.size});

  final FanController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    return Semantics(
      button: true,
      label: 'Power',
      child: Material(
        color: fan.surfaceHi,
        shape: CircleBorder(side: BorderSide(color: fan.accent, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: controller.busy
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  controller.send(controller.profile.power);
                },
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Symbols.power_settings_new_rounded,
              size: size * 0.52,
              color: fan.accent,
              fill: 1,
              weight: 700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BoostButton extends StatelessWidget {
  const _BoostButton({required this.controller, required this.dialSize});

  final FanController controller;
  final double dialSize;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    final diameter = dialSize * 0.37;
    final on = controller.boostOn;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Material(
        shape: const CircleBorder(),
        color: on ? fan.accent : fan.surfaceHi,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: controller.busy
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  controller.toggleBoost();
                },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.bolt_rounded,
                size: diameter * 0.3,
                fill: 1,
                color: on ? fan.onAccent : fan.onSurface,
              ),
              const SizedBox(height: 2),
              Text(
                'BOOST',
                style: TextStyle(
                  fontSize: diameter * 0.12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: on ? fan.onAccent : fan.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});

  final FanController controller;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    final error = controller.lastError;
    final showing = controller.busy || error != null;

    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: showing ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: controller.busy ? null : controller.resyncToMinimum,
              style: TextButton.styleFrom(
                foregroundColor: fan.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Resync'),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: showing ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                error ?? controller.lastAction ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: error != null ? fan.accent : fan.onMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showAboutDialogForApp(BuildContext context) {
  final fan = context.fan;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: fan.surface,
      icon: Icon(Symbols.info_rounded, size: 32, color: fan.accent),
      title: const Text('Pigeon Fan Remote'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AboutRow(label: 'Author', value: AppInfo.author),
          _AboutRow(label: 'Email', value: AppInfo.email),
          _AboutRow(label: 'Version', value: AppInfo.version),
          _AboutRow(label: 'Version code', value: AppInfo.versionCode),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom(foregroundColor: fan.accent),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final fan = context.fan;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: fan.onMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fan.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
