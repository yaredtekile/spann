import Combine
import SwiftUI

@main
struct SpannApp: App {
    @StateObject private var store: TrackerStore
    private let idleMonitor: IdleMonitor

    init() {
        let trackerStore = TrackerStore()
        _store = StateObject(wrappedValue: trackerStore)
        idleMonitor = IdleMonitor(store: trackerStore)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .onAppear {
                    idleMonitor.start()
                }
                .onOpenURL { url in
                    store.handle(url)
                }
        } label: {
            MenuBarLabel()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Window("Time History", id: "history") {
            HistoryView()
                .environmentObject(store)
                .frame(minWidth: 760, minHeight: 580)
        }
        .defaultSize(width: 920, height: 700)

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject private var store: TrackerStore
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if store.isRunning {
            HStack(spacing: 5) {
                Image(systemName: store.activeTimer?.isPaused == true ? "pause.fill" : "record.circle.fill")
                Text(store.elapsed(at: now).spannClockText)
                    .monospacedDigit()
            }
            .onReceive(ticker) { now = $0 }
        } else {
            Image(systemName: "hourglass")
                .accessibilityLabel("Spann")
        }
    }
}
