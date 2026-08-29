import Charts
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var selectedProjectID: UUID?

    private var filteredEntries: [TimeEntry] {
        store.entries
            .filter { selectedProjectID == nil || $0.projectID == selectedProjectID }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private var groupedEntries: [(date: Date, entries: [TimeEntry])] {
        Dictionary(grouping: filteredEntries) {
            Calendar.current.startOfDay(for: $0.startedAt)
        }
        .map { (date: $0.key, entries: $0.value) }
        .sorted { $0.date > $1.date }
    }

    private var weekData: [DayTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(date: date, seconds: filteredTotal(on: date))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                titleSection
                summarySection
                weekChart
                entriesSection
            }
            .padding(32)
        }
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient(
                    colors: [Color.orange.opacity(0.07), .clear, Color.teal.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    private var titleSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("TIME LEDGER")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(2.1)
                    .foregroundStyle(.secondary)
                Text("Your work, in focus.")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-1)
            }

            Spacer()

            Picker("Project", selection: $selectedProjectID) {
                Text("All projects").tag(nil as UUID?)
                ForEach(store.projects) { project in
                    Text(project.name).tag(project.id as UUID?)
                }
            }
            .frame(width: 190)
        }
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "TODAY",
                value: filteredTotal(on: .now).spannCompactText,
                symbol: "sun.max.fill",
                tint: .orange
            )
            summaryCard(
                title: "THIS WEEK",
                value: weekData.reduce(0) { $0 + $1.seconds }.spannCompactText,
                symbol: "calendar",
                tint: .teal
            )
            summaryCard(
                title: "SESSIONS",
                value: "\(filteredEntries.count)",
                symbol: "square.stack.3d.up.fill",
                tint: .blue
            )
        }
    }

    private func summaryCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.primary.opacity(0.07))
                )
        )
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("LAST 7 DAYS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            Chart(weekData) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .day),
                    y: .value("Hours", item.seconds / 3_600)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                    AxisTick()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(hours, specifier: "%.0f")h")
                        }
                    }
                }
            }
            .frame(height: 170)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.primary.opacity(0.035))
        )
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SESSIONS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            if groupedEntries.isEmpty {
                ContentUnavailableView(
                    "No time recorded",
                    systemImage: "hourglass",
                    description: Text("Start a project from the menu bar. Finished sessions appear here.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ForEach(groupedEntries, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(group.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            Text(group.entries.reduce(0) { $0 + $1.duration }.spannCompactText)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        ForEach(group.entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        let project = store.project(for: entry.projectID)

        return HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 3)
                .fill(project?.color ?? .secondary)
                .frame(width: 5, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(project?.name ?? "Archived project")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text("\(entry.startedAt.formatted(date: .omitted, time: .shortened)) – \(entry.endedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.duration.spannClockText)
                .font(.system(size: 13, weight: .medium, design: .monospaced))

            Button(role: .destructive) {
                store.delete(entryID: entry.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Delete session")
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.035))
        )
    }

    private func filteredTotal(on day: Date) -> TimeInterval {
        guard let selectedProjectID else {
            return store.total(on: day)
        }

        let calendar = Calendar.current
        return store.entries
            .filter {
                $0.projectID == selectedProjectID &&
                calendar.isDate($0.startedAt, inSameDayAs: day)
            }
            .reduce(0) { $0 + $1.duration }
            + (
                store.activeTimer?.projectID == selectedProjectID &&
                calendar.isDate(store.activeTimer?.startedAt ?? .distantPast, inSameDayAs: day)
                ? store.elapsed()
                : 0
            )
    }
}

private struct DayTotal: Identifiable {
    let date: Date
    let seconds: TimeInterval

    var id: Date { date }
}
