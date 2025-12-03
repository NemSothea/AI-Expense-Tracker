//
//  AIAssistantView.swift
//  AIExpenseTracker
//
//  Created by Alfian Losari on 09/06/24.
//

import ChatGPTUI
import SwiftUI

let apiKey = ""
let _senderImage = "https://avatars.githubusercontent.com/u/17895030?v=4"
let _botImage = "https://cdn-icons-png.flaticon.com/512/4712/4712038.png"

enum ChatType: String, Identifiable, CaseIterable {
    case text = "Text"
    case voice = "Voice"
    var id: Self { self }
}

struct AIAssistantView: View {
    
    
    
    @State var textChatVM = AIAssistantTextChatViewModel(apiKey: apiKey)
    @State var voiceChatVM = AIAssistantVoiceChatViewModel(apiKey: apiKey)
    @State var chatType = ChatType.text
    
    let suggestions = [
           "What did I spend most on this month?",
           "How can I save more money?",
           "Show me my monthly spending trend",
           "What's my budget status?",
           "Suggest a budget plan"
       ]
    
    var body: some View {
        VStack(spacing: 0) {
            Picker(selection: $chatType, label: Text("Chat Type").font(.system(size: 12, weight: .bold))) {
                ForEach(ChatType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            #if !os(iOS)
            .padding(.vertical)
            #endif
            
            // Suggestion Labels - Only show for text chat
            if chatType == .text {
                suggestionSection
            }
            
            Divider()
            
            ZStack {
                switch chatType {
                case .text:
                    TextChatView(customContentVM: textChatVM)
                case .voice:
                    VoiceChatView(customContentVM: voiceChatVM)
                }
            }.frame(maxWidth: 1024, alignment: .center)
        }
        #if !os(macOS)
        .navigationBarTitle("AI Expense Assistant", displayMode: .inline)
        #endif
    }
    var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick suggestions")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            sendSuggestion(suggestion)
                        }) {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        
#if os(iOS)
        .background(Color(.systemGray6).opacity(0.4))
     #elseif os(macOS)
     // macOS system colors
        .background(Color(.windowBackgroundColor).opacity(0.4))
#endif
    }
    
    func sendSuggestion(_ suggestion: String) {
        // Remove emoji for cleaner input
        let cleanSuggestion = suggestion
            .replacingOccurrences(of: "💰 ", with: "")
            .replacingOccurrences(of: "📊 ", with: "")
            .replacingOccurrences(of: "🎯 ", with: "")
            .replacingOccurrences(of: "📈 ", with: "")
            .replacingOccurrences(of: "💡 ", with: "")
            .replacingOccurrences(of: "🔍 ", with: "")
        
        textChatVM.inputMessage = cleanSuggestion
        Task { @MainActor in
            await textChatVM.sendTapped()
        }
    }
}



//#Preview {
//    AIAssistantView()
//}
