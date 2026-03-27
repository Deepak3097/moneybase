//
//  ApiEndpoint.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

enum ApiEndpoint {
    case marketSummary(region: String)
    case stockSummary(symbol: String, region: String)

    func makeURL(host: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host

        switch self {
        case .marketSummary(let region):
            components.path = "/market/v2/get-summary"
            components.queryItems = [
                URLQueryItem(name: "region", value: region)
            ]
        case .stockSummary(let symbol, let region):
            components.path = "/stock/get-fundamentals"
            components.queryItems = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "region", value: region),
                URLQueryItem(name: "modules", value: "summaryProfile")
            ]
        }

        return components.url
    }
}
