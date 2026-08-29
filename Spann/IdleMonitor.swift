import AppKit
import CoreGraphics
import Foundation

enum InputMonitoringPermission {
    static var isGranted: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    static func request() -> Bool {
        CGRequestListenEventAccess()
    }

    static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

@MainActor
final class IdleMonitor {
    private static let activityEventTypes: [CGEventType] = [
        .keyDown,
        .keyUp,
        .flagsChanged,
        .mouseMoved,
        .leftMouseDown,
        .leftMouseUp,
        .leftMouseDragged,
        .rightMouseDown,
        .rightMouseUp,
        .rightMouseDragged,
        .otherMouseDown,
        .otherMouseUp,
        .otherMouseDragged,
        .scrollWheel
    ]

    private weak var store: TrackerStore?
    private var timer: Timer?
    private var promptedDuringCurrentIdle = false

    init(store: TrackerStore) {
        self.store = store
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleState()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        checkIdleState()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkIdleState() {
        guard let store else { return }
        guard InputMonitoringPermission.isGranted else { return }

        let idleSeconds = Self.activityEventTypes
            .map {
                CGEventSource.secondsSinceLastEventType(
                    .combinedSessionState,
                    eventType: $0
                )
            }
            .min() ?? 0

        if idleSeconds < 5 {
            promptedDuringCurrentIdle = false
            return
        }

        let threshold = TimeInterval(store.idleThresholdMinutes * 60)
        guard
            threshold > 0,
            store.isActivelyCounting,
            idleSeconds >= threshold,
            !promptedDuringCurrentIdle
        else {
            return
        }

        promptedDuringCurrentIdle = true
        presentIdlePrompt(idleSeconds: idleSeconds)
    }

    private func presentIdlePrompt(idleSeconds: TimeInterval) {
        guard let store else { return }

        let now = Date()
        let idleStart = now.addingTimeInterval(-idleSeconds)
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Still working?"
        alert.informativeText = """
        No keyboard or mouse activity was detected since \(formatter.string(from: idleStart)).
        What should Spann do with this time?
        """
        alert.icon = NSImage(systemSymbolName: "moon.zzz.fill", accessibilityDescription: nil)
        alert.addButton(withTitle: "Keep Time")
        alert.addButton(withTitle: "Remove Idle Time")
        alert.addButton(withTitle: "Pause at \(formatter.string(from: idleStart))")
        alert.addButton(withTitle: "Stop at \(formatter.string(from: idleStart))")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            store.excludeIdleTime(startingAt: idleStart, endingAt: now)
        } else if response == .alertThirdButtonReturn {
            store.pause(at: idleStart)
        } else if response.rawValue == NSApplication.ModalResponse.alertThirdButtonReturn.rawValue + 1 {
            store.stop(at: idleStart)
        }
    }
}
