//
//  FinanceRepository.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct FinanceRepository: StockRepository {
    private let config: APIConfiguration
    private let client: HTTPClient

    init(config: APIConfiguration, client: HTTPClient) {
        self.config = config
        self.client = client
    }

    func fetchStocks() async throws -> [StockListItem] {
        guard let url = ApiEndpoint.marketSummary(region: "US").makeURL(host: config.rapidAPIHost) else {
            throw APIError.invalidResponse
        }

        let data = try await client.get(url: url, headers: requestHeaders)

        let decoded: MarketSummaryResponse
        do {
            decoded = try JSONDecoder().decode(MarketSummaryResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }

        let summaryItems: [MarketSummaryItem] = decoded.marketSummaryAndSparkResponse?.result ?? []

        let mapped: [StockListItem] = summaryItems.compactMap { result in
                guard let symbol = result.symbol, !symbol.isEmpty else {
                    return nil
                }

                let name = (result.shortName?.isEmpty == false ? result.shortName : nil) ?? symbol
                return StockListItem(
                    symbol: symbol,
                    displayName: name,
                    exchangeName: result.fullExchangeName,
                    price: result.regularMarketPrice?.raw,
                    changePercent: result.regularMarketChangePercent?.raw
                )
            }
            .sorted { $0.symbol < $1.symbol }

        guard !mapped.isEmpty else {
            throw APIError.noResults(nil)
        }

        return mapped
    }

    func fetchStockDetail(symbol: String) async throws -> StockDetail {
        guard let url = ApiEndpoint.stockSummary(symbol: symbol, region: "US").makeURL(host: config.rapidAPIHost) else {
            throw APIError.invalidResponse
        }

        let data = try await client.get(url: url, headers: requestHeaders)

        let decoded: StockSummaryResponse
        do {
            decoded = try JSONDecoder().decode(StockSummaryResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }

        guard let profile = decoded.quoteSummary?.result?.first?.summaryProfile else {
            throw APIError.noResults(decoded.quoteSummary?.error?.description)
        }

        let addressParts = [
            profile.address1,
            profile.address2,
            profile.city,
            profile.zip,
            profile.country
        ].compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }

        let address = addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")
        let industry = profile.industryDisp ?? profile.industry

        return StockDetail(
            symbol: symbol,
            displayName: profile.name ?? symbol,
            sector: profile.sector,
            industry: industry,
            website: profile.website,
            phone: profile.phone,
            address: address,
            businessSummary: profile.longBusinessSummary ?? profile.description
        )
    }

    private var requestHeaders: [String: String] {
        [
            "x-rapidapi-key": config.rapidAPIKey,
            "x-rapidapi-host": config.rapidAPIHost
        ]
    }
}
