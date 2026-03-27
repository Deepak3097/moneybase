//
//  MarketSummaryItem.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct MarketSummaryItem: Decodable {
    let symbol: String?
    let shortName: String?
    let fullExchangeName: String?
    let regularMarketPrice: RawValue<Double>?
    let regularMarketChangePercent: RawValue<Double>?
}

struct RawValue<T: Decodable>: Decodable {
    let raw: T?

    private enum CodingKeys: String, CodingKey {
        case raw
    }

    init(from decoder: Decoder) throws {
        if let directValue = try? T(from: decoder) {
            raw = directValue
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        raw = try container.decodeIfPresent(T.self, forKey: .raw)
    }
}
