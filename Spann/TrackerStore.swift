import Combine
import Foundation
import WidgetKit

@MainActor
final class TrackerStore: ObservableObject {
    @Published private(set) var projects: [SpannProject] = []
    @Published private(set) var entries: [TimeEntry] = []
    @Published private(set) var activeTimer: ActiveTimer?
    @Published private(set) var idleThresholdMinutes = 10

    private let storageKey = "spann.trackerData.v1"
    private var defaults: UserDefaults {
        UserDefaults(suiteName: SharedTimerStorage.suiteName) ?? .standard
    }

    init() {
        load()
        updateSharedSnapshot()
    }

    var activeProject: SpannProject? {
        guard let projectID = activeTimer?.projectID else { return nil }
        return projects.first { $0.id == projectID }
    }

    var isRunning: Bool {
        activeTimer != nil
    }

    var isActivelyCounting: Bool {
        activeTimer != nil && activeTimer?.isPaused == false
    }

    var availableProjects: [SpannProject] {
        projects
            .filter { !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }

    @discardableResult
    func createProject(named rawName: String) -> SpannProject? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let color = ProjectColors.all[projects.count % ProjectColors.all.count]
        let project = SpannProject(name: name, colorHex: color)
        projects.append(project)
        persist()
        return project
    }

    func start(projectID: UUID, at date: Date = .now) {
        guard projects.contains(where: { $0.id == projectID && !$0.isArchived }) else { return }

        if activeTimer?.projectID == projectID {
            if activeTimer?.isPaused == true {
                resume(at: date)
            }
            return
        }

        if activeTimer != nil {
            stop(at: date)
        }

        activeTimer = ActiveTimer(
            projectID: projectID,
            startedAt: date,
            excludedSeconds: 0,
            pausedAt: nil
        )
        persist()
    }

    func pause(at date: Date = .now) {
        guard var timer = activeTimer, timer.pausedAt == nil else { return }
        timer.pausedAt = date
        activeTimer = timer
        persist()
    }

    func resume(at date: Date = .now) {
        guard var timer = activeTimer, let pausedAt = timer.pausedAt else { return }
        timer.excludedSeconds += max(0, date.timeIntervalSince(pausedAt))
        timer.pausedAt = nil
        activeTimer = timer
        persist()
    }

    func togglePause(at date: Date = .now) {
        if activeTimer?.isPaused == true {
            resume(at: date)
        } else {
            pause(at: date)
        }
    }

    func stop(at requestedDate: Date = .now) {
        guard var timer = activeTimer else { return }
        let endDate = max(requestedDate, timer.startedAt)

        if let pausedAt = timer.pausedAt {
            timer.excludedSeconds += max(0, endDate.timeIntervalSince(pausedAt))
        }

        let entry = TimeEntry(
            projectID: timer.projectID,
            startedAt: timer.startedAt,
            endedAt: endDate,
            excludedSeconds: timer.excludedSeconds
        )

        if entry.duration >= 1 {
            entries.append(entry)
        }
        activeTimer = nil
        persist()
    }

    func excludeIdleTime(startingAt idleStart: Date, endingAt date: Date = .now) {
        guard var timer = activeTimer, timer.pausedAt == nil else { return }
        let effectiveStart = max(idleStart, timer.startedAt)
        timer.excludedSeconds += max(0, date.timeIntervalSince(effectiveStart))
        activeTimer = timer
        persist()
    }

    func setIdleThreshold(minutes: Int) {
        idleThresholdMinutes = max(0, minutes)
        persist()
    }

    func archive(projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        if activeTimer?.projectID == projectID {
            stop()
        }
        projects[index].isArchived = true
        persist()
    }

    func delete(entryID: UUID) {
        entries.removeAll { $0.id == entryID }
        persist()
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        activeTimer?.elapsed(at: date) ?? 0
    }

    func project(for id: UUID) -> SpannProject? {
        projects.first { $0.id == id }
    }

    func total(for projectID: UUID) -> TimeInterval {
        let saved = entries
            .filter { $0.projectID == projectID }
            .reduce(0) { $0 + $1.duration }
        let active = activeTimer?.projectID == projectID ? elapsed() : 0
        return saved + active
    }

    func total(on day: Date, now: Date = .now) -> TimeInterval {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let interval = DateInterval(start: dayStart, end: dayEnd)

        let saved = entries.reduce(0) { result, entry in
            result + duration(of: entry, inside: interval)
        }

        guard let timer = activeTimer else { return saved }
        let activeEnd = timer.pausedAt ?? now
        let overlapStart = max(timer.startedAt, interval.start)
        let overlapEnd = min(activeEnd, interval.end)
        let active = max(0, overlapEnd.timeIntervalSince(overlapStart) - timer.excludedSeconds)
        return saved + active
    }

    func handle(_ url: URL) {
        switch url.host {
        case "toggle":
            togglePause()
        case "stop":
            stop()
        default:
            break
        }
    }

    private func duration(of entry: TimeEntry, inside interval: DateInterval) -> TimeInterval {
        let overlapStart = max(entry.startedAt, interval.start)
        let overlapEnd = min(entry.endedAt, interval.end)
        guard overlapEnd > overlapStart else { return 0 }

        let rawEntryDuration = entry.endedAt.timeIntervalSince(entry.startedAt)
        let overlap = overlapEnd.timeIntervalSince(overlapStart)
        guard rawEntryDuration > 0 else { return 0 }
        let proportionalExclusion = entry.excludedSeconds * (overlap / rawEntryDuration)
        return max(0, overlap - proportionalExclusion)
    }

    private func load() {
        guard
            let data = defaults.data(forKey: storageKey),
            let stored = try? JSONDecoder().decode(PersistedTrackerData.self, from: data)
        else {
            return
        }

        projects = stored.projects
        entries = stored.entries
        activeTimer = stored.activeTimer
        idleThresholdMinutes = stored.idleThresholdMinutes
    }

    private func persist() {
        let data = PersistedTrackerData(
            projects: projects,
            entries: entries,
            activeTimer: activeTimer,
            idleThresholdMinutes: idleThresholdMinutes
        )

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: storageKey)
        }
        updateSharedSnapshot()
    }

    private func updateSharedSnapshot(at date: Date = .now) {
        let state: SharedTimerSnapshot.State
        if activeTimer?.isPaused == true {
            state = .paused
        } else if activeTimer != nil {
            state = .running
        } else {
            state = .stopped
        }

        SharedTimerStorage.save(
            SharedTimerSnapshot(
                state: state,
                projectName: activeProject?.name,
                elapsedSeconds: elapsed(at: date),
                todaySeconds: total(on: date, now: date),
                updatedAt: date
            )
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "SpannTimerWidget")
    }
}
