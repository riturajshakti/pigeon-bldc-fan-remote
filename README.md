# Pigeon Fan Remote

Turn your phone into a remote for a Pigeon BLDC ceiling fan.

### 🌐 [pigeon-fan-remote.pages.dev](https://pigeon-fan-remote.pages.dev/) — download the app

| The app | On your home screen |
|---|---|
| <img src="https://pigeon-fan-remote.pages.dev/assets/images/dark.jpg" width="220" alt="Remote screen, dark theme"> | <img src="https://pigeon-fan-remote.pages.dev/assets/images/widget-dark.jpg" width="220" alt="Home screen widgets, dark theme"> |
| <img src="https://pigeon-fan-remote.pages.dev/assets/images/light.jpg" width="220" alt="Remote screen, light theme"> | <img src="https://pigeon-fan-remote.pages.dev/assets/images/widget-light.jpg" width="220" alt="Home screen widgets, light theme"> |

## What it does

- All the buttons from the original remote: Power, Light, Timer, Reverse, Sleep, Boost, and speed up and down
- **Pick a speed directly from 1 to 5** — the original remote can only step up and down one at a time
- Slide your finger around the dial to change speed
- **Two home screen widgets** — one solid, one see-through — so you can control the fan without opening the app
- Matches your phone's light or dark theme

## Before you install

**Your phone needs an IR blaster.** This is the small infrared window that real
remotes use to send signals. Most phones do not have one. If yours does not, the
app cannot control anything — there is no way around it.

Phones that often have one include many Xiaomi, Redmi, POCO, OnePlus and realme
models. Check your phone's specifications if you are not sure.

The app was built and tested on a POCO X6.

## Installing

1. Open [pigeon-fan-remote.pages.dev](https://pigeon-fan-remote.pages.dev/) on your phone
2. Tap the download button
3. Open the downloaded file
4. Android will warn you about installing outside the Play Store — allow it when asked

The app only sends infrared signals. It has no internet access, no accounts, and
nothing leaves your phone.

## Adding a widget

Press and hold an empty spot on your home screen, choose **Widgets**, find
**Pigeon Fan**, and drag one out. There are two to choose from:

- **Pigeon Fan** — solid background
- **Pigeon Fan (transparent)** — see-through, so your wallpaper shows behind it

Both work the same way and stay in sync with each other and with the app.

## Will it work with my fan?

Probably only if you have the same fan. The signals in this app were worked out
by testing against one specific Pigeon BLDC ceiling fan, and a different fan
almost certainly uses different ones.

If the app installs but your fan ignores it, that is why — it is not broken, it
just does not speak your fan's language. The repository includes the tool used to
work out the signals, so a developer could repeat the process for another fan.

## A note on speed

When you tap a speed, the fan may briefly run down to its lowest setting before
coming back up. That is deliberate. The fan never reports what speed it is
actually at, so the app returns to a known point and counts up from there. It
takes a moment, but it always lands on the right speed — even if someone used the
physical remote in between.

## Questions or problems

Open an [issue](https://github.com/riturajshakti/pigeon-bldc-fan-remote/issues)
or email riturajshakti@gmail.com.

---

## For developers

<details>
<summary>Building, the IR protocol, and project layout</summary>

### Build

```bash
flutter pub get
./build_release.sh
```

APKs land in `outputs/assets/apks/`. The release build is signed with the debug
key — fine for sideloading, not for distribution. Add a keystore and a
`signingConfig` in `android/app/build.gradle.kts` before publishing anywhere.

Requires Flutter 3.47+ and a device with an IR emitter. The manifest declares
`android.permission.TRANSMIT_IR`, granted at install time.

### The protocol

Found by sweeping the command space and testing each response against the real
fan — not taken from any remote database.

| Setting | Value |
|---|---|
| Protocol | NEC |
| Carrier | 38 kHz |
| Address | 0 |

| Function | Code | Function | Code |
|---|---|---|---|
| Power | 129 | Boost | 142 |
| Sleep | 135 | Speed − | 146 |
| Reverse | 136 | Speed + | 149 |
| Light | 140 | Timer | 150 |

A different BLDC fan will likely use the same NEC framing with different command
bytes. The discovery screens are in
[`assets/BldcRemoteLab/`](assets/BldcRemoteLab/README.md) — a 0–255 sweep grid
and a per-button code editor with selectable NEC variants.

### Absolute speed from relative commands

The receiver only accepts `+` and `−`. To reach a known level the app sends five
`−` presses to floor the fan, then counts up. That makes speed selection correct
regardless of prior state, including after someone used the physical remote. The
gap between transmissions is 1 ms, tuned on real hardware.

### Boost

Boost is one-way on this fan: pressing it again does not cancel it. Boost clears
only on a speed command (1–5, `−`, or Resync). Every Boost press still transmits,
so a missed signal can be retried.

### Layout

```
lib/
  fan_profile.dart    verified IR codes
  protocol.dart       NEC encoder
  fan_controller.dart speed/boost state and sequencing
  home_screen.dart    remote UI
  ir_service.dart     MethodChannel to Android
android/app/src/main/kotlin/.../
  MainActivity.kt      ConsumerIrManager bridge
  FanIr.kt             NEC encoder for the widgets
  FanWidgetProvider.kt both home screen widgets
  FanState.kt          state shared between app and widgets
```

The NEC encoder exists twice, in Dart and Kotlin, because a home screen widget
cannot run Flutter. Changing a code means changing both `fan_profile.dart` and
`FanIr.kt`.

### Download site

`outputs/` is the site at
[pigeon-fan-remote.pages.dev](https://pigeon-fan-remote.pages.dev/). The page and
screenshots are tracked; the APKs are not, since git would keep every version of
a 15 MB binary forever. Build first, then deploy:

```bash
npx wrangler pages deploy outputs
```

</details>

---

Built by Rituraj Shakti. Not affiliated with Pigeon.
