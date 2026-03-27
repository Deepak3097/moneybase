import Foundation

enum StockDetailState: Equatable {
    case idle
    case loading
    case loaded(StockDetail)
    case error(String)
}

@MainActor
final class StockDetailViewModel {
    var onStateChanged: ((StockDetailState) -> Void)?

    private(set) var state: StockDetailState = .idle {
        didSet { onStateChanged?(state) }
    }

    private let repository: StockRepository

    init(repository: StockRepository) {
        self.repository = repository
    }

    func load(symbol: String) async {
        state = .loading

        do {
            let detail = try await repository.fetchStockDetail(symbol: symbol)
            state = .loaded(detail)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
