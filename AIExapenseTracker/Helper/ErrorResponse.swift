//
//  ErrorResponse.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//
import SwiftUI
import Alamofire

struct ErrorResponse: Codable, Sendable {
    let message: String?
    let timestamp: String?
    let status: Int?
}
// MARK: - Enhanced Network Error
enum NetworkError: LocalizedError, Sendable {
    case unauthorized
    case serverError(String)
    case alamofireError(AFError)
    case cannotConnectToServer
    case timeout
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please login again"
        case .serverError(let message):
            return message
        case .alamofireError(let error):
            return error.localizedDescription
        case .cannotConnectToServer:
            return "Cannot connect to server. Please check if the server is running and your network connection."
        case .timeout:
            return "Request timed out. Please check your network connection."
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
