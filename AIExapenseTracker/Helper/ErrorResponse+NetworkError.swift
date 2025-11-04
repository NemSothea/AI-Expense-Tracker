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
    case cannotConnectToServer(URLError?)
    case timeout
    case invalidResponse
    case decodingError
    case connectionRefused
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please login again"
        case .serverError(let message):
            return message
        case .alamofireError(let error):
            // Extract meaningful info from AFError
            return extractAFErrorMessage(error)
        case .cannotConnectToServer(let urlError):
            return getConnectionErrorMessage(urlError)
        case .timeout:
            return "Request timed out. Please check your network connection."
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .connectionRefused:
            return "Server is not running. Please start your backend server on localhost:8080"
        }
    }
    
    // Helper to extract meaningful messages from AFError
    private func extractAFErrorMessage(_ error: AFError) -> String {
        if let underlyingError = error.underlyingError as? URLError {
            return getConnectionErrorMessage(underlyingError)
        }
        
        switch error {
        case .sessionTaskFailed(let error):
            return "Network error: \(error.localizedDescription)"
        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                return "Server error: HTTP \(code)"
            default:
                return "Response validation failed"
            }
        default:
            return error.localizedDescription
        }
    }
    
    // Helper to get user-friendly connection error messages
    private func getConnectionErrorMessage(_ urlError: URLError?) -> String {
        guard let urlError = urlError else {
            return "Cannot connect to server. Please check if the server is running."
        }
        
        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost:
            return "Cannot connect to server. Please check:\n• Server is running on localhost:8080\n• No firewall blocking the connection"
        case .timedOut:
            return "Connection timed out. Server might be busy or offline."
        case .notConnectedToInternet:
            return "No internet connection. Please check your network."
        case .networkConnectionLost:
            return "Network connection lost. Please try again."
        case .dnsLookupFailed:
            return "Cannot find the server. Please check the server address."
        default:
            return "Network error: \(urlError.localizedDescription)"
        }
    }
    
    // Static method to convert URLError to NetworkError
    static func fromURLError(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost:
            // Check for specific connection refused error (code 61)
            if urlError.errorCode == -1004 {
                return .connectionRefused
            }
            return .cannotConnectToServer(urlError)
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .cannotConnectToServer(urlError)
        case .userAuthenticationRequired, .secureConnectionFailed:
            return .unauthorized
        default:
            return .cannotConnectToServer(urlError)
        }
    }
    
    // Static method to convert AFError to NetworkError
    static func fromAFError(_ afError: AFError) -> NetworkError {
        if let underlyingError = afError.underlyingError as? URLError {
            return .fromURLError(underlyingError)
        }
        
        if case let .responseValidationFailed(reason) = afError,
           case let .unacceptableStatusCode(code) = reason {
            if code == 401 {
                return .unauthorized
            }
            return .serverError("Server error: HTTP \(code)")
        }
        
        return .alamofireError(afError)
    }
    
   
    
    // Helper property to check if it's a connection error
    var isConnectionError: Bool {
        switch self {
        case .cannotConnectToServer, .timeout, .connectionRefused:
            return true
        case .alamofireError(let afError):
            if let underlyingError = afError.underlyingError as? URLError {
                let networkError = NetworkError.fromURLError(underlyingError)
                return networkError.isConnectionError
            }
            return false
        default:
            return false
        }
    }
}
