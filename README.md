# Spann

Spann is a local-first macOS time tracker built for the menu bar.

## First version

- Create and archive projects
- Start, pause, resume, switch, and stop timers
- See the live timer in the macOS menu bar
- Review daily and weekly history
- Detect idle keyboard/mouse time and resolve it explicitly
- Add a desktop or Notification Center widget
- Optionally launch at login

All tracking data is stored locally in the `group.com.spann.tracker` app group.

## Development

Requirements:

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Generate and open the project:

```sh
xcodegen generate
open Spann.xcodeproj
```

Select a development team for both the **Spann** and **SpannWidget** targets so the shared App Group entitlement can be signed. Then run the **Spann** scheme.

To add the widget, open Notification Center, choose **Edit Widgets**, and search for **Spann**.
