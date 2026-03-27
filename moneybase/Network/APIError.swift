//
//  APIError.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case invalidStatusCode(Int)
    case decodingFailed
    case noResults(String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .invalidStatusCode(let statusCode):
            return "Server returned status code \(statusCode)."
        case .decodingFailed:
            return "Failed to decode response."
        case .noResults(let message):
            return message ?? "No stock data available."
        }
    }
}
