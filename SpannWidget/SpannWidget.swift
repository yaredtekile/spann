import SwiftUI
import WidgetKit

struct SpannWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedTimerSnapshot
}

struct SpannWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpannWidgetEntry {
        SpannWidgetEntry(
            date: .now,
            snapshot: SharedTimerSnapshot(
                state: .running,
                projectName: "Deep Work",
                elapsedSeconds: 4_382,
                todaySeconds: 10_540,
                updatedAt: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SpannWidgetEntry) -> Void) {
        completion(SpannWidgetEntry(date: .now, snapshot: SharedTimerStorage.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpannWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = SharedTimerStorage.load()
        let entries = (0..<6).compactMap { minute -> SpannWidgetEntry? in
            guard let date = Calendar.current.date(byAdding: .minute, value: minute, to: now) else {
                return nil
            }
            return SpannWidgetEntry(date: date, snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(5 * 60))))
    }
}

struct SpannTimerWidget: Widget {
    let kind = "SpannTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpannWidgetProvider()) { entry in
            SpannWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        Color(nsColor: .windowBackgroundColor)
                        RadialGradient(
                            colors: [Color.orange.opacity(0.22), .clear],
                            center: .topTrailing,
                            startRadius: 0,
                            endRadius: 240
                        )
                    }
                }
        }
        .configurationDisplayName("Spann Timer")
        .description("See your active project and control its timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct SpannWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SpannWidgetEntry

    var body: some View {
        standardView
    }

    private var standardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("SPANN", systemImage: "hourglass")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.1)
                Spacer()
                Circle()
                    .fill(entry.snapshot.state == .running ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 6, height: 6)
            }

            Spacer()

            Text(entry.snapshot.projectName ?? "Ready to focus")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(.secondary)

            timerText
                .font(.system(size: family == .systemSmall ? 24 : 30, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Spacer()

            HStack {
                Label(liveTodayTotal.spannCompactText, systemImage: "sun.max")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                if entry.snapshot.state != .stopped {
                    Link(destination: URL(string: "spann://toggle")!) {
                        Image(systemName: entry.snapshot.state == .paused ? "play.fill" : "pause.fill")
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.primary.opacity(0.09)))
                    }

                    Link(destination: URL(string: "spann://stop")!) {
                        Image(systemName: "stop.fill")
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.primary.opacity(0.09)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timerText: some View {
        if entry.snapshot.state == .running {
            Text(entry.snapshot.effectiveStartDate, style: .timer)
                .monospacedDigit()
        } else {
            Text(entry.snapshot.elapsedSeconds.spannClockText)
                .monospacedDigit()
        }
    }

    private var liveTodayTotal: TimeInterval {
        let liveIncrement = entry.snapshot.state == .running
            ? max(0, entry.date.timeIntervalSince(entry.snapshot.updatedAt))
            : 0
        return entry.snapshot.todaySeconds + liveIncrement
    }
}
