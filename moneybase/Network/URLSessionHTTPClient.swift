//
//  URLSessionHTTPClient.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

protocol HTTPClient {
    func get(url: URL, headers: [String: String]) async throws -> Data
}

struct URLSessionHTTPClient: HTTPClient {
    func get(url: URL, headers: [String: String]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidStatusCode(httpResponse.statusCode)
        }

        return data
    }
}
