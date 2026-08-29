import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section("Idle detection") {
                Picker("Ask me after", selection: idleBinding) {
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("Never").tag(0)
                }

                Text("Spann checks the time since the last keyboard or mouse event. It never records what you type or click.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("General") {
                Toggle("Launch Spann at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        updateLoginItem(enabled: enabled)
                    }

                if let loginItemError {
                    Text(loginItemError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Widget") {
                Text("Open Notification Center, choose Edit Widgets, then search for Spann. Widget controls open the menu-bar app to apply changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Label("All projects and time history stay on this Mac.", systemImage: "lock.shield.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 410)
    }

    private var idleBinding: Binding<Int> {
        Binding(
            get: { store.idleThresholdMinutes },
            set: { store.setIdleThreshold(minutes: $0) }
        )
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            loginItemError = "macOS could not update the login item: \(error.localizedDescription)"
        }
    }
}
