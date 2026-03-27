import Foundation

protocol StockRepository {
    func fetchStocks() async throws -> [StockListItem]
    func fetchStockDetail(symbol: String) async throws -> StockDetail
}






