# Code discovery screens

The screens used to find this fan's IR codes. They are not part of the shipped app
— once the protocol was known they were lifted out and kept here, both as a record
of how the codes were found and as a starting point for anyone doing the same for
a different fan.

## What they do

- **`lib/sweep_screen.dart`** — a grid of 256 circular buttons, one per command byte.
  Tap to transmit, long-press to record what the fan did (no effect / something
  happened / identified) and add a note. This is what found the Pigeon codes: sitting
  under the fan, walking the command space, marking each reaction.
- **`lib/remote_screen.dart`** — eight labelled buttons, each with an editable code
  field, plus protocol, address, carrier frequency and repeat-count settings, and a
  JSON export of everything discovered.
- **`lib/lab_screen.dart`** — tabbed wrapper hosting both.
- **`lib/app_state.dart`** — settings and persistence for codes and sweep marks.
- **`lib/protocol.dart`** — NEC frame encoder with selectable variants (standard NEC,
  NEC-extended 16-bit address, and a NEC-shaped frame with no inverted bytes).
- **`lib/ir_service.dart`** — MethodChannel wrapper over Android's `ConsumerIrManager`.
- **`widget_test.dart`** — tests for the protocol encoder, including the exact bit
  pattern for a known command.

## Why the protocol is a setting, not a constant

When you start, you do not know the framing. These screens make the frame format a
dropdown rather than a hardcoded assumption, so a wrong guess costs a tap instead of
a rebuild. The address matters just as much: NEC receivers ignore frames whose
address byte is not theirs, so if a full 0–255 sweep is silent, vary the address
before concluding the protocol is wrong.

## To revive

Drop `lib/` into a Flutter project with `shared_preferences`, add the Kotlin
MethodChannel handler and `android.permission.TRANSMIT_IR` to the manifest. The
channel name is `com.raj.pigeon_fan_remote/ir` — rename it for your own app.

`LabScreen` was reached through a hidden long-press on the home screen title.

## How the Pigeon codes were found

Protocol NEC, carrier 38 kHz, address 0, and the eight commands clustered in
129–150. The tight clustering is typical: a vendor's remote usually uses a small
contiguous block, so once one code responds the rest are close by.

Full results are in the main [README](../../README.md).
