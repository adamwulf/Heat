import SwiftUI
import OSLog
import HeatKit

private let logger = Logger(subsystem: "ConversationView", category: "Heat")

struct ConversationView: View {
    @Environment(Store.self) var store
    @Environment(ConversationViewModel.self) var conversationViewModel
    
    @State private var isShowingError = false
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 4) {
                    
                    // Messages
                    ForEach(conversationViewModel.messagesVisible) { message in
                        MessageBubble(message: message)
                    }
                    
                    // Typing indicator
                    if conversationViewModel.conversation?.state == .processing {
                        TypingIndicator(.leading)
                    }
                    
                    // Suggestions
                    if conversationViewModel.conversation?.state == .suggesting {
                        TypingIndicator(.trailing)
                    }
                    SuggestionList(suggestions: conversationViewModel.suggestions) { suggestion in
                        SuggestionView(suggestion: suggestion, action: { handleSuggestion(.init($0)) })
                    }
                    
                    ScrollMarker(id: "bottom")
                }
                .padding(.horizontal)
                .padding(.top, 64)
                .onChange(of: conversationViewModel.conversationID) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: conversationViewModel.conversation?.modified) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .background(.background)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, alignment: .center) {
            ConversationInput()
                .environment(conversationViewModel)
                .padding()
                .background(.background)
        }
        .alert(isPresented: $isShowingError, error: conversationViewModel.error) { _ in
            Button("Dismiss", role: .cancel) {
                isShowingError = false
                conversationViewModel.error = nil
            }
        } message: {
            Text($0.recoverySuggestion)
        }
        .onChange(of: conversationViewModel.error) { _, newValue in
            guard newValue != nil else { return }
            isShowingError = true
        }
    }
    
    func handleSuggestion(_ suggestion: String) {
        if conversationViewModel.conversationID == nil {
            conversationViewModel.newConversation()
        }
        do {
            try conversationViewModel.generate(suggestion)
        } catch let error as HeatKitError {
            conversationViewModel.error = error
        } catch {
            logger.warning("failed to submit: \(error)")
        }
    }
}

struct ScrollMarker: View {
    let id: String
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .id(id)
    }
}

#Preview {
    NavigationStack {
        ConversationView()
    }
    .environment(Store.preview)
    .environment(ConversationViewModel(store: Store.preview))
}
