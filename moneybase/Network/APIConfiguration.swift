//
//  APIConfiguration.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct APIConfiguration {
    let rapidAPIKey: String
    let rapidAPIHost: String

    init(
        rapidAPIKey: String,
        rapidAPIHost: String = "yh-finance.p.rapidapi.com"
    ) {
        self.rapidAPIKey = rapidAPIKey
        self.rapidAPIHost = rapidAPIHost
    }

    init(bundle: Bundle = .main) throws {
        let key = (bundle.object(forInfoDictionaryKey: "RAPIDAPI_KEY") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let host = (bundle.object(forInfoDictionaryKey: "RAPIDAPI_HOST") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !key.isEmpty else {
            throw AppConfigurationError.missingRapidAPIKey
        }

        self.rapidAPIKey = key
        self.rapidAPIHost = host.isEmpty ? "yh-finance.p.rapidapi.com" : host
    }
}
