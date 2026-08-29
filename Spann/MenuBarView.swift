import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: TrackerStore
    @Environment(\.openWindow) private var openWindow
    @State private var newProjectName = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            timerCard
            projectsSection
            footer
        }
        .frame(width: 356)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                RadialGradient(
                    colors: [Color.orange.opacity(0.11), .clear],
                    center: .topTrailing,
                    startRadius: 10,
                    endRadius: 280
                )
            }
        )
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.primary)
                        .frame(width: 27, height: 27)
                    Image(systemName: "hourglass")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                }

                Text("SPANN")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.6)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(store.isActivelyCounting ? Color.green : Color.secondary.opacity(0.45))
                    .frame(width: 6, height: 6)
                Text(store.isActivelyCounting ? "TRACKING" : store.isRunning ? "PAUSED" : "READY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var timerCard: some View {
        VStack(spacing: 14) {
            if let project = store.activeProject {
                HStack(spacing: 7) {
                    Circle()
                        .fill(project.color)
                        .frame(width: 8, height: 8)
                    Text(project.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                }

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(store.elapsed(at: context.date).spannClockText)
                        .font(.system(size: 38, weight: .medium, design: .monospaced))
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 10) {
                    Button {
                        store.togglePause()
                    } label: {
                        Label(
                            store.activeTimer?.isPaused == true ? "Resume" : "Pause",
                            systemImage: store.activeTimer?.isPaused == true ? "play.fill" : "pause.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SpannPrimaryButtonStyle())

                    Button {
                        store.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(SpannSecondaryButtonStyle())
                    .help("Stop and save this timer")
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT WILL YOU\nMAKE TIME FOR?")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .tracking(-0.4)
                    Text("Choose a project below to begin.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                )
        )
        .padding(.horizontal, 12)
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("PROJECTS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("TODAY \(store.total(on: .now).spannCompactText)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if store.availableProjects.isEmpty {
                Text("Create your first project, then press play.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 3) {
                    ForEach(store.availableProjects) { project in
                        projectRow(project)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("New project", text: $newProjectName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .onSubmit(createProject)

                Button(action: createProject) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(Color.primary.opacity(0.13))
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private func projectRow(_ project: SpannProject) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(project.color)
                .frame(width: 5, height: 25)

            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(store.total(for: project.id).spannCompactText)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.start(projectID: project.id)
            } label: {
                Image(systemName: store.activeTimer?.projectID == project.id ? "waveform" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(store.activeTimer?.projectID == project.id ? project.color : .primary)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.primary.opacity(0.07)))
            }
            .buttonStyle(.plain)
            .disabled(store.activeTimer?.projectID == project.id && store.activeTimer?.isPaused == false)
        }
        .padding(.horizontal, 8)
        .frame(height: 42)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Archive Project", role: .destructive) {
                store.archive(projectID: project.id)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button {
                openWindow(id: "history")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("History", systemImage: "chart.bar.xaxis")
            }

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color.primary.opacity(0.035))
    }

    private func createProject() {
        if let project = store.createProject(named: newProjectName) {
            newProjectName = ""
            if !store.isRunning {
                store.start(projectID: project.id)
            }
        }
    }
}

private struct SpannPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.72 : 0.92))
            )
    }
}

private struct SpannSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0.07))
            )
    }
}
