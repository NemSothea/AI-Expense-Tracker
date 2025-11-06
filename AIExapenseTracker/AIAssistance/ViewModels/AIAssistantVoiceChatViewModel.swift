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
final class AIAssistantVoiceChatViewModel: VoiceChatViewModel<AIAssistantResponseView> {
    
    let functionsManager: FunctionsManager

    init(apiKey: String, model: ChatGPTModel = .gpt_hyphen_4o) {
        self.functionsManager = .init(apiKey: apiKey)
        super.init(model: model, apiKey: apiKey)
        self.functionsManager.addLogConfirmationCallback = { [weak self] isConfirmed, props in
            guard let self else { return }
            
            await MainActor.run {
                let text: String
                if isConfirmed {
                    // Handle the async operation
                    Task {
                        do {
                            guard let user = await AuthManager.shared.currentUser else {
                                throw NetworkError.unauthorized
                            }
                            let request = ExpenseRequest(from: props.log, userId: user.id)
                            
                            _ =  try await ExpenseService.shared.createExpense(request)
                            
                            await MainActor.run {
                                let response = AIAssistantResponse(
                                    text: "Sure, i've added this log to your expenses list",
                                    type: .addExpenseLog(.init(
                                        log: props.log,
                                        messageID: nil,
                                        userConfirmation: .confirmed,
                                        confirmationCallback: props.confirmationCallback
                                    ))
                                )
                                self.updateStateWithResponse(response)
                            }
                        } catch {
                            await MainActor.run {
                                // Handle error appropriately
                                let response = AIAssistantResponse(
                                    text: "Sorry, there was an error adding the expense",
                                    type: .addExpenseLog(.init(
                                        log: props.log,
                                        messageID: nil,
                                        userConfirmation: .cancelled,
                                        confirmationCallback: props.confirmationCallback
                                    ))
                                )
                                self.updateStateWithResponse(response)
                            }
                        }
                    }
                    return
                } else {
                    text = "Ok, i won't be adding this log"
                    let response = AIAssistantResponse(
                        text: text,
                        type: .addExpenseLog(.init(
                            log: props.log,
                            messageID: nil,
                            userConfirmation: .cancelled,
                            confirmationCallback: props.confirmationCallback
                        ))
                    )
                    self.updateStateWithResponse(response)
                }
            }
        }
    }

    // Helper method to update state
    @MainActor
    private func updateStateWithResponse(_ response: AIAssistantResponse) {
        if self.state.idleResponse != nil {
            self.state = .idle(.customContent({ AIAssistantResponseView(response: response) }))
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
