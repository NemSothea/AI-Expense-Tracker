//
//  AIAssistantVoiceChatViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import ChatGPTUI
import Foundation
import Observation
import ChatGPTSwift


@Observable
class AIAssistantVoiceChatViewModel: VoiceChatViewModel<AIAssistantResponseView> {
    
    let functionsManager: FunctionsManager
    let db = ExpenseService.shared
    
    init(apiKey: String, model: ChatGPTModel = .gpt_hyphen_4o) {
        self.functionsManager = .init(apiKey: apiKey)
        super.init(model: model, apiKey: apiKey)
        self.functionsManager.addLogConfirmationCallback = { [weak self] isConfirmed, props in
            guard let self else {
                return
            }
            let text: String
            if isConfirmed {
                do {
                    // 2) Map the assistant log to your API request
                    
                    
//                    let req = ExpenseRequest(
//                        userId:
//                        name: props.log.name,
//                        amount: props.log.amount,
//                        categoryId: props.log.categoryEnum.backendId, // implement mapping once
//                        date: props.log.dateText // "yyyy-MM-dd"
//                    )
//
//                    // 3) Call your backend
//                    _ = try await expenseService.createExpense(req)

                    text = "Sure, I’ve added this log to your expenses list"
                } catch {
                    text = "I couldn’t add the log (network/error)."
                }
            } else {
                text = "Ok, I won’t be adding this log"
            }
            
            let response = AIAssistantResponse(text: text, type: .addExpenseLog(.init(log: props.log, messageID: nil, userConfirmation: isConfirmed ? .confirmed : .cancelled, confirmationCallback: props.confirmationCallback)))
            
            if let _  = self.state.idleResponse {
                self.state = .idle(.customContent({ AIAssistantResponseView(response: response)}))
            }
        }
    }

    override func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                let prompt = try await api.generateAudioTransciptions(audioData: audioData)
                try Task.checkCancellation()
                
                let response = try await functionsManager.prompt(prompt, model: model)
                try Task.checkCancellation()
                
                let data = try await api.generateSpeechFrom(input: response.text, voice:
                        .init(rawValue: selectedVoice.rawValue) ?? .alloy)
                try Task.checkCancellation()
                
                try self.playAudio(data: data, response: .customContent({ AIAssistantResponseView(response: response)}))
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }
}
