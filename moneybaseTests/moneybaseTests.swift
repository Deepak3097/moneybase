import XCTest
@testable import moneybase

final class moneybaseTests: XCTestCase {

    @MainActor
    func testRefreshPublishesLoadingThenLoaded() async {
        let repository = MockStockRepository()
        repository.stocksResult = .success(Self.sampleStocks)

        let viewModel = StocksListViewModel(repository: repository)
        var states: [StocksListState] = []
        viewModel.onStateChanged = { states.append($0) }

        await viewModel.refresh()

        XCTAssertEqual(repository.fetchStocksCallCount, 1)
        XCTAssertEqual(states.first, .loading)

        guard case .loaded(let stocks, _) = states.last else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(stocks.count, 3)
    }

    @MainActor
    func testSearchFiltersByDisplayNameAndSymbol() async {
        let repository = MockStockRepository()
        repository.stocksResult = .success(Self.sampleStocks)

        let viewModel = StocksListViewModel(repository: repository)
        await viewModel.refresh()

        viewModel.updateSearch(text: "apple")
        XCTAssertEqual(viewModel.filteredStocks.map(\.symbol), ["AAPL"])

        viewModel.updateSearch(text: "SFT")
        XCTAssertEqual(viewModel.filteredStocks.map(\.symbol), ["MSFT"])

        viewModel.updateSearch(text: "")
        XCTAssertEqual(viewModel.filteredStocks.count, 3)
    }

    @MainActor
    func testRefreshPublishesErrorOnFailure() async {
        let repository = MockStockRepository()
        repository.stocksResult = .failure(MockError.testFailure)

        let viewModel = StocksListViewModel(repository: repository)
        await viewModel.refresh()

        guard case .error(let message) = viewModel.state else {
            return XCTFail("Expected error state")
        }

        XCTAssertTrue(message.contains("failure"))
    }

    @MainActor
    func testAutoRefreshTriggersRepeatedFetches() async {
        let repository = MockStockRepository()
        repository.stocksResult = .success(Self.sampleStocks)

        let viewModel = StocksListViewModel(repository: repository, refreshInterval: 0.01)

        viewModel.startAutoRefresh()
        try? await Task.sleep(nanoseconds: 60_000_000)
        viewModel.stopAutoRefresh()

        XCTAssertGreaterThanOrEqual(repository.fetchStocksCallCount, 2)
    }

    @MainActor
    func testDetailViewModelPublishesLoadedState() async {
        let repository = MockStockRepository()
        repository.detailResult = .success(
            StockDetail(
                symbol: "AAPL",
                displayName: "AAPL",
                sector: "Technology",
                industry: "Consumer Electronics",
                website: "https://www.apple.com",
                phone: "1-408-996-1010",
                address: "One Apple Park Way, Cupertino, CA, 95014, United States",
                businessSummary: "Designs, manufactures, and markets smartphones and personal computers."
            )
        )

        let viewModel = StockDetailViewModel(repository: repository)
        await viewModel.load(symbol: "AAPL")

        XCTAssertEqual(repository.fetchStockDetailCallCount, 1)

        guard case .loaded(let detail) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(detail.symbol, "AAPL")
        XCTAssertEqual(detail.displayName, "AAPL")
    }

    private static let sampleStocks: [StockListItem] = [
        StockListItem(symbol: "AAPL", displayName: "Apple Inc.", exchangeName: "NasdaqGS", price: 201.23, changePercent: 1.12),
        StockListItem(symbol: "MSFT", displayName: "Microsoft Corp.", exchangeName: "NasdaqGS", price: 421.01, changePercent: -0.23),
        StockListItem(symbol: "NVDA", displayName: "NVIDIA Corp.", exchangeName: "NasdaqGS", price: 905.87, changePercent: 2.43)
    ]
}

private enum MockError: LocalizedError {
    case testFailure

    var errorDescription: String? {
        switch self {
        case .testFailure:
            return "Repository failure"
        }
    }
}

private final class MockStockRepository: StockRepository {
    var stocksResult: Result<[StockListItem], Error> = .success([])
    var detailResult: Result<StockDetail, Error> = .failure(MockError.testFailure)

    private(set) var fetchStocksCallCount = 0
    private(set) var fetchStockDetailCallCount = 0

    func fetchStocks() async throws -> [StockListItem] {
        fetchStocksCallCount += 1
        return try stocksResult.get()
    }

    func fetchStockDetail(symbol: String) async throws -> StockDetail {
        fetchStockDetailCallCount += 1
        return try detailResult.get()
    }
}
