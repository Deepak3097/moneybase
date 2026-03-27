//
//  StockSummary.swift
//  moneybase
//
//  Created by Deepak Gupta on 27/03/26.
//

import Foundation

struct StockSummary: Decodable {
	let result: [StockSummaryResult]?
	let error: StockSummaryError?
}

struct StockSummaryResult: Decodable {
	let summaryProfile: SummaryProfile?
}

struct StockSummaryError: Decodable {
	let code: String?
	let description: String?
}
