//
//  AppConfigurationError.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

enum AppConfigurationError: LocalizedError {
    case missingRapidAPIKey

    var errorDescription: String? {
        switch self {
        case .missingRapidAPIKey:
            return "Missing RAPIDAPI_KEY in Info.plist."
        }
    }
}
