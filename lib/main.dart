import 'package:flutter/material.dart';

import 'fan_controller.dart';
import 'fan_profile.dart';
import 'home_screen.dart';
import 'ir_service.dart';
import 'theme.dart';

void main() {
  runApp(const PigeonRemoteApp());
}

class PigeonRemoteApp extends StatefulWidget {
  const PigeonRemoteApp({super.key});

  @override
  State<PigeonRemoteApp> createState() => _PigeonRemoteAppState();
}

class _PigeonRemoteAppState extends State<PigeonRemoteApp> {
  final FanController _controller = FanController(IrService(), pigeonBldcProfile);

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => MaterialApp(
        title: 'Pigeon Fan Remote',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: switch (_controller.theme) {
          ThemeChoice.system => ThemeMode.system,
          ThemeChoice.light => ThemeMode.light,
          ThemeChoice.dark => ThemeMode.dark,
        },
        home: HomeScreen(controller: _controller),
      ),
    );
  }
}
