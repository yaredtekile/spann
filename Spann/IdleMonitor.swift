import AppKit
import CoreGraphics
import Foundation

@MainActor
final class IdleMonitor {
    private weak var store: TrackerStore?
    private var timer: Timer?
    private var promptedDuringCurrentIdle = false

    init(store: TrackerStore) {
        self.store = store
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleState()
            }
        }
        checkIdleState()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkIdleState() {
        guard let store else { return }

        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .null
        )

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
        alert.addButton(withTitle: "Stop at \(formatter.string(from: idleStart))")

        switch alert.runModal() {
        case .alertSecondButtonReturn:
            store.excludeIdleTime(startingAt: idleStart, endingAt: now)
        case .alertThirdButtonReturn:
            store.stop(at: idleStart)
        default:
            break
        }
    }
}
