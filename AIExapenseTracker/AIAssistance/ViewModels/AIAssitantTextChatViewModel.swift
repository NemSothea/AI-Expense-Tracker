//
//  AIAssitantTextChatViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 26/12/24.
//


import ChatGPTSwift
import ChatGPTUI
import Observation
import Foundation

@Observable
class AIAssistantTextChatViewModel: TextChatViewModel<AIAssistantResponseView> {
    
    let functionsManager: FunctionsManager
   
    
    init(apiKey: String, model: ChatGPTModel = .gpt_hyphen_4o) {
        self.functionsManager = .init(apiKey: apiKey)
        super.init(
            senderImage: "https://avatar.iran.liara.run/public/boy",
            botImage: "https://cdn-icons-png.flaticon.com/512/4712/4712038.png",
            model: model,
            apiKey: apiKey
        )
        
        self.functionsManager.addLogConfirmationCallback = { [weak self] isConfirmed, props in
            guard let self,
                  let id = props.messageID,
                  let index = self.messages.firstIndex(where: { $0.id == id }) else { return }
            
            // If user cancels, update immediately (no async work)
            if !isConfirmed {
                var messageRow = self.messages[index]
                let response = AIAssistantResponse(
                    text: "Ok, I won’t be adding this log",
                    type: .addExpenseLog(.init(log: props.log,
                                               messageID: id,
                                               userConfirmation: .cancelled,
                                               confirmationCallback: props.confirmationCallback))
                )
                messageRow.response = .customContent({ AIAssistantResponseView(response: response) })
                self.messages[index] = messageRow
                return
            }
            
            // User confirmed — perform async API call
            Task {
                let responseText: String
                do {
                    guard let user = await AuthManager.shared.currentUser else {
                        throw NetworkError.unauthorized
                    }
                    let request = ExpenseRequest(from: props.log, userId: user.id)
                    _ = try await ExpenseService.shared.createExpense(request)
                    responseText = "Sure, I’ve added this log to your expenses list"
                } catch {
                    responseText = "I couldn’t add the log (network/error)."
                }
                
                await MainActor.run {
                    // Re-lookup index in case messages changed
                    guard let idx = self.messages.firstIndex(where: { $0.id == id }) else { return }
                    var messageRow = self.messages[idx]
                    let response = AIAssistantResponse(
                        text: responseText,
                        type: .addExpenseLog(.init(log: props.log,
                                                   messageID: id,
                                                   userConfirmation: .confirmed,
                                                   confirmationCallback: props.confirmationCallback))
                    )
                    messageRow.response = .customContent({ AIAssistantResponseView(response: response) })
                    self.messages[idx] = messageRow
                }
            }
        }
    }
    
    
    @MainActor
    override func sendTapped() async {
        self.task = Task {
            let text = inputMessage
            inputMessage = ""
            await callFunction(text)
        }
    }
    
    @MainActor
    override func retry(message: MessageRow<AIAssistantResponseView>) async {
        self.task = Task {
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
                return
            }
            self.messages.remove(at: index)
            await callFunction(message.sendText)
        }
    }
    
    @MainActor
    func callFunction(_ prompt: String) async {
        isPrompting = true
        var messageRow = MessageRow<AIAssistantResponseView>(
            isPrompting: true,
            sendImage: senderImage,
            send: .rawText(prompt),
            responseImage: botImage,
            response: .rawText(""),
            responseError: nil)
        
        self.messages.append(messageRow)
        
        do {
            let response = try await functionsManager.prompt(prompt, model: model, messageID: messageRow.id)
            messageRow.response = .customContent({ AIAssistantResponseView(response: response)})
        } catch {
            messageRow.responseError = error.localizedDescription
        }
        
        messageRow.isPrompting = false
        self.messages[self.messages.count - 1] = messageRow
        isPrompting = false
        
    }
    
}
