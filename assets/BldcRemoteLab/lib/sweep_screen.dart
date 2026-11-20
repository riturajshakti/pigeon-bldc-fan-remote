import 'package:flutter/material.dart';

import 'app_state.dart';

class SweepScreen extends StatelessWidget {
  const SweepScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Legend(state: state),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SizedBoxGridDelegate(),
            itemCount: 256,
            itemBuilder: (context, code) => _CodeButton(state: state, code: code),
          ),
        ),
      ],
    );
  }
}

class SizedBoxGridDelegate extends SliverGridDelegateWithMaxCrossAxisExtent {
  const SizedBoxGridDelegate()
      : super(maxCrossAxisExtent: 64, mainAxisSpacing: 8, crossAxisSpacing: 8);
}

class _Legend extends StatelessWidget {
  const _Legend({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final tested = state.sweepMarks.values
        .where((m) => m != SweepMark.untested)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap to send · long-press to mark the result',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final mark in SweepMark.values)
                if (mark != SweepMark.untested)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _colorFor(mark, context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(_labelFor(mark), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
              Text('$tested/256 marked', style: Theme.of(context).textTheme.bodySmall),
              GestureDetector(
                onTap: () => _confirmClear(context),
                child: Text(
                  'reset',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset sweep results?'),
        content: const Text('This clears every mark and note. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              state.clearSweep();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

Color _colorFor(SweepMark mark, BuildContext context) => switch (mark) {
      SweepMark.untested => Theme.of(context).colorScheme.surfaceContainerHighest,
      SweepMark.noEffect => Colors.grey.shade700,
      SweepMark.didSomething => Colors.amber.shade700,
      SweepMark.identified => Colors.green.shade600,
    };

String _labelFor(SweepMark mark) => switch (mark) {
      SweepMark.untested => 'untested',
      SweepMark.noEffect => 'no effect',
      SweepMark.didSomething => 'something happened',
      SweepMark.identified => 'identified',
    };

class _CodeButton extends StatelessWidget {
  const _CodeButton({required this.state, required this.code});

  final AppState state;
  final int code;

  @override
  Widget build(BuildContext context) {
    final mark = state.sweepMarks[code] ?? SweepMark.untested;
    final hasNote = state.sweepNotes.containsKey(code);
    final bg = _colorFor(mark, context);
    final fg = mark == SweepMark.untested
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => state.send(code),
      onLongPress: () => _showMarkSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$code',
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
            if (hasNote)
              Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.sticky_note_2, size: 10, color: fg),
              ),
          ],
        ),
      ),
    );
  }

  void _showMarkSheet(BuildContext context) {
    final noteController = TextEditingController(text: state.sweepNotes[code] ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code $code  ·  0x${code.toRadixString(16).toUpperCase().padLeft(2, '0')}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final mark in SweepMark.values)
              ListTile(
                dense: true,
                leading: Icon(Icons.circle, color: _colorFor(mark, ctx), size: 16),
                title: Text(_labelFor(mark)),
                trailing: (state.sweepMarks[code] ?? SweepMark.untested) == mark
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  state.markSweep(code, mark);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'What did the fan do?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (text) {
                state.noteSweep(code, text.trim());
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => state.send(code),
                    icon: const Icon(Icons.send),
                    label: const Text('Send again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      state.noteSweep(code, noteController.text.trim());
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save note'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
