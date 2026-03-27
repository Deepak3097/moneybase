//
//  StockListItem.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

struct StockListItem: Equatable {
    let symbol: String
    let displayName: String
    let exchangeName: String?
    let price: Double?
    let changePercent: Double?
}
