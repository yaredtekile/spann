# Spann

Spann is a local-first macOS time tracker that lives in the menu bar. It keeps
project timers close at hand without requiring an account, browser tab, or
cloud service.

- Site: [spann.yared.site](https://spann.yared.site)
- Source: [github.com/yaredtekile/spann](https://github.com/yaredtekile/spann)

> Spann is currently an early unsigned preview. macOS may show an unidentified
> developer warning until the app is notarized.

## Why I built it

I wanted a small time tracker that stays out of the way while I work. Most time
tracking tools either require too much setup or quietly keep counting after I
walk away from my computer.

Spann focuses on a simple workflow: choose a project, start working, and keep an
accurate record of the time. When the Mac has been inactive, Spann asks what
should happen instead of guessing or recording hours of idle time.

The app is local-first by design. Project names and time history remain on the
Mac.

## Features

- Create and archive projects
- Start, pause, resume, switch, and stop timers
- See the live timer in the macOS menu bar
- Review daily and weekly history
- Detect keyboard, mouse, trackpad, and scrolling inactivity
- Keep, remove, pause, or stop time from an idle prompt
- Choose an idle threshold from Settings
- Add a small or medium macOS widget
- Optionally launch Spann at login

## Requirements

- macOS 14 or later
- Xcode 16 or later
- [Homebrew](https://brew.sh) for installing XcodeGen
- An Apple development team selected in Xcode

## Build and install

1. Clone the repository:

   ```sh
   git clone https://github.com/yaredtekile/spann.git
   cd spann
   ```

2. Install XcodeGen:

   ```sh
   brew install xcodegen
   ```

3. Generate the Xcode project:

   ```sh
   xcodegen generate
   open Spann.xcodeproj
   ```

4. In Xcode, open **Signing & Capabilities** and select your development team
   for both the **Spann** and **SpannWidget** targets.

5. Make sure both targets use the same App Group. The project currently uses
   `group.com.spann.tracker`.

6. Select the **Spann** scheme and press **Run**.

If the bundle identifiers are already registered to another team, change the
app bundle identifiers and the App Group in `project.yml`, both entitlement
files, and `Shared/SharedTimerSnapshot.swift`. Run `xcodegen generate` again
after making those changes.

## How to use Spann

### Track a project

1. Click the hourglass in the menu bar.
2. Enter a project name and press Return or click **+**. The first project
   starts immediately.
3. Use **Pause**, **Resume**, or **Stop** from the timer card.
4. Press the play button beside another project to switch to it. Spann saves
   the current session before starting the new one.

### Review history

Open the menu-bar panel and select **History**. The ledger shows today's time,
the current week's total, a seven-day chart, and individual sessions. Use the
project picker to filter the history.

### Enable idle detection

1. Open Spann from the menu bar.
2. Select **Allow** in the idle-detection permission card.
3. Approve Spann under **System Settings → Privacy & Security → Input
   Monitoring** if macOS asks.
4. Open **Settings** in Spann and choose the inactivity threshold.

While a timer is running, Spann checks for inactivity every 15 seconds. When
the threshold is reached, the prompt can:

- Keep the idle period
- Remove the idle period and continue
- Pause at the beginning of the idle period
- Stop at the beginning of the idle period

Spann only reads the duration since the last input event. It does not record
keys, clicks, cursor positions, applications, screenshots, or screen contents.

### Add the widget

1. Open macOS Notification Center.
2. Select **Edit Widgets**.
3. Search for **Spann**.
4. Add the small or medium timer widget.

The widget displays the active project, elapsed time, and today's total. Its
controls open Spann to pause, resume, or stop the active timer.

## Data storage

Projects, timer state, history, and widget snapshots are stored locally through
the `group.com.spann.tracker` App Group. Spann currently has no account system,
analytics, or cloud synchronization.

## License

Spann is open source under the [MIT License](LICENSE).
