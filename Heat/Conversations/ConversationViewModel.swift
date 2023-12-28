import SwiftUI
import OSLog
import HeatKit
import GenKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

@Observable
final class ConversationViewModel {
    let store: Store
    
    var conversationID: String?

    init(store: Store, chatID: String? = nil) {
        self.store = store
        self.conversationID = conversationID
    }
    
    var conversation: Conversation? {
        guard let conversationID = conversationID else { return nil }
        return store.get(conversationID: conversationID)
    }
    
    var model: Model? {
        guard let conversation = conversation else { return nil }
        return store.get(modelID: conversation.modelID)
    }
    
    var messages: [Message] {
        guard let conversation = conversation else { return [] }
        return conversation.messages.filter { $0.kind != .instruction }
    }
    
    func change(model: Model) {
        guard var conversation = conversation else { return }
        conversation.modelID = model.id
        store.upsert(conversation: conversation)
    }
    
    func generateResponse(content: String) {
        guard let conversationID = conversationID else { return }
        guard let url = store.preferences.host else {
            logger.warning("missing ollama host url")
            return
        }
        guard let model = model else { return }
        let message = Message(role: .user, content: content)
        
        generateTask = Task {
            await MessageManager(messages: messages)
                .append(message: message)
                .sink { store.upsert(messages: $0, conversationID: conversationID) }
                .generate(service: OllamaService(url: url), model: model.name)
                .sink { store.upsert(messages: $0, conversationID: conversationID) }
        }
    }
    
    func cancel() {
        generateTask?.cancel()
    }
    
    private var generateTask: Task<(), Error>? = nil
}
