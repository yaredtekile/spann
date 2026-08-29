import Foundation
import SwiftUI

struct SpannProject: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    let createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        createdAt: Date = .now,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

struct TimeEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let projectID: UUID
    var startedAt: Date
    var endedAt: Date
    var excludedSeconds: TimeInterval

    init(
        id: UUID = UUID(),
        projectID: UUID,
        startedAt: Date,
        endedAt: Date,
        excludedSeconds: TimeInterval = 0
    ) {
        self.id = id
        self.projectID = projectID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.excludedSeconds = excludedSeconds
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt) - excludedSeconds)
    }
}

struct ActiveTimer: Codable, Equatable {
    let projectID: UUID
    let startedAt: Date
    var excludedSeconds: TimeInterval
    var pausedAt: Date?

    var isPaused: Bool {
        pausedAt != nil
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        let end = pausedAt ?? date
        return max(0, end.timeIntervalSince(startedAt) - excludedSeconds)
    }
}

struct PersistedTrackerData: Codable {
    var projects: [SpannProject]
    var entries: [TimeEntry]
    var activeTimer: ActiveTimer?
    var idleThresholdMinutes: Int
}

enum ProjectColors {
    static let all = [
        "FF6B35",
        "2A9D8F",
        "3A86FF",
        "E9C46A",
        "9B5DE5",
        "E76F51"
    ]
}

extension Color {
    init(hex: String) {
        let value = Int(hex, radix: 16) ?? 0xFF6B35
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
