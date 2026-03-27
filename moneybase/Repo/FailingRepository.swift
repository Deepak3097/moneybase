//
//  FailingRepository.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct FailingRepository: StockRepository {
    let error: Error

    func fetchStocks() async throws -> [StockListItem] {
        throw error
    }

    func fetchStockDetail(symbol: String) async throws -> StockDetail {
        throw error
    }
}
