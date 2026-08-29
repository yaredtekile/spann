import Foundation

struct SharedTimerSnapshot: Codable, Equatable {
    enum State: String, Codable {
        case stopped
        case running
        case paused
    }

    var state: State
    var projectName: String?
    var elapsedSeconds: TimeInterval
    var todaySeconds: TimeInterval
    var updatedAt: Date

    static let empty = SharedTimerSnapshot(
        state: .stopped,
        projectName: nil,
        elapsedSeconds: 0,
        todaySeconds: 0,
        updatedAt: .now
    )

    var effectiveStartDate: Date {
        updatedAt.addingTimeInterval(-elapsedSeconds)
    }
}

enum SharedTimerStorage {
    static let suiteName = "group.com.spann.tracker"
    static let snapshotKey = "spann.sharedTimerSnapshot"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func load() -> SharedTimerSnapshot {
        guard
            let data = defaults.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(SharedTimerSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }

    static func save(_ snapshot: SharedTimerSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }
}

extension TimeInterval {
    var spannClockText: String {
        let total = max(0, Int(self.rounded(.down)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var spannCompactText: String {
        let totalMinutes = max(0, Int(self) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
