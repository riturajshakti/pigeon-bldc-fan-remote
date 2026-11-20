import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'protocol.dart';

class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsCard(state: state),
        const SizedBox(height: 16),
        for (final button in fanButtons) ...[
          _ButtonRow(state: state, label: button),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showExport(context),
          icon: const Icon(Icons.download),
          label: const Text('Export findings as JSON'),
        ),
      ],
    );
  }

  void _showExport(BuildContext context) {
    final json = state.exportJson();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Findings'),
        content: SingleChildScrollView(
          child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final caps = state.capabilities;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  caps?.hasEmitter == true ? Icons.settings_remote : Icons.error_outline,
                  color: caps?.hasEmitter == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    caps == null
                        ? 'Probing IR hardware…'
                        : caps.hasEmitter
                            ? 'IR emitter available'
                            : 'No IR emitter on this device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (caps != null && caps.hasEmitter) ...[
              const SizedBox(height: 4),
              Text(
                caps.carrierRanges.isEmpty
                    ? 'Carrier ranges: not reported by the driver'
                    : 'Carrier ranges: ${caps.carrierRanges.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 24),
            DropdownButtonFormField<IrProtocol>(
              initialValue: state.protocol,
              decoration: const InputDecoration(labelText: 'Frame format', isDense: true),
              items: [
                for (final p in protocols)
                  DropdownMenuItem(value: p, child: Text(p.name)),
              ],
              onChanged: (p) => p == null ? null : state.setProtocol(p),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: 'Address',
                    value: state.address,
                    onChanged: state.setAddress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Carrier Hz',
                    value: state.frequency,
                    onChanged: (v) => state.setCarrierOverride(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    label: 'Repeats',
                    value: state.repeats,
                    onChanged: state.setRepeats,
                  ),
                ),
              ],
            ),
            if (state.lastError != null) ...[
              const SizedBox(height: 10),
              Text(
                state.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(_NumberField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && '${widget.value}' != _controller.text) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: widget.label, isDense: true),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}

class _ButtonRow extends StatefulWidget {
  const _ButtonRow({required this.state, required this.label});

  final AppState state;
  final String label;

  @override
  State<_ButtonRow> createState() => _ButtonRowState();
}

class _ButtonRowState extends State<_ButtonRow> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.buttonCodes[widget.label]?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.state.buttonCodes[widget.label];
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: FilledButton(
            onPressed: code == null ? null : () => widget.state.send(code),
            child: Text(widget.label, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'code',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              widget.state.setButtonCode(
                widget.label,
                parsed != null && parsed >= 0 && parsed <= 255 ? parsed : null,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            code == null ? 'no code set' : '0x${code.toRadixString(16).toUpperCase().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
