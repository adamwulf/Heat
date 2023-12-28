import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "MainApp", category: "Heat")

@main
struct MainApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var store = Store.shared
    @State private var conversationViewModel = ConversationViewModel(store: Store.shared)
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ConversationView()
            }
            .onChange(of: scenePhase) { _, _ in
                handlePhaseChange()
            }
            .onAppear {
                handleRestore()
            }
        }
        .environment(store)
        .environment(conversationViewModel)
    }
    
    func handleRestore() {
        Task {
            do {
                try await store.restore()
                handleModels()
            } catch {
                logger.error("Persistence Restore: \(error, privacy: .public)")
            }
        }
    }
    
    func handleSave() async {
        do { try await store.saveAll() }
        catch { logger.error("Persistence Save: \(error, privacy: .public)") }
    }
    
    func handlePhaseChange() {
        guard scenePhase == .background else { return }
        Task { await handleSave() }
    }
    
    func handleModels() {
        guard let host = Bundle.main.infoDictionary?["OllamaHost"] as? String else {
            return
        }
        guard let url = URL(string: host) else {
            return
        }
        Task {
            await ModelManager(url: url, models: store.models)
                .refresh()
                .sink { store.upsert(models: $0) }
        }
    }
}
