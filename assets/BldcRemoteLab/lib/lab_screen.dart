import 'package:flutter/material.dart';

import 'app_state.dart';
import 'ir_service.dart';
import 'remote_screen.dart';
import 'sweep_screen.dart';

class LabScreen extends StatefulWidget {
  const LabScreen({super.key});

  static const route = '/lab';

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> with SingleTickerProviderStateMixin {
  final AppState _state = AppState(IrService());
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Code Lab'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(icon: Icon(Icons.settings_remote), text: 'Remote'),
              Tab(icon: Icon(Icons.grid_on), text: 'Sweep 0–255'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            RemoteScreen(state: _state),
            SweepScreen(state: _state),
          ],
        ),
      ),
    );
  }
}
