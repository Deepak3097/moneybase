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
    func testSearchTrimsWhitespace() async {
        let repository = MockStockRepository()
        repository.stocksResult = .success(Self.sampleStocks)

        let viewModel = StocksListViewModel(repository: repository)
        await viewModel.refresh()

        viewModel.updateSearch(text: "  aapl ")
        XCTAssertEqual(viewModel.filteredStocks.map(\.symbol), ["AAPL"])
    }

    @MainActor
    func testStockAtReturnsNilWhenIndexOutOfRange() async {
        let repository = MockStockRepository()
        repository.stocksResult = .success(Self.sampleStocks)

        let viewModel = StocksListViewModel(repository: repository)
        await viewModel.refresh()

        XCTAssertNil(viewModel.stock(at: 99))
    }

    @MainActor
    func testUpdateSearchBeforeFirstRefreshKeepsIdleState() async {
        let repository = MockStockRepository()
        let viewModel = StocksListViewModel(repository: repository)

        viewModel.updateSearch(text: "AAPL")
        XCTAssertEqual(viewModel.state, .idle)
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

    @MainActor
    func testDetailViewModelPublishesErrorOnFailure() async {
        let repository = MockStockRepository()
        repository.detailResult = .failure(MockError.testFailure)

        let viewModel = StockDetailViewModel(repository: repository)
        await viewModel.load(symbol: "AAPL")

        guard case .error(let message) = viewModel.state else {
            return XCTFail("Expected error state")
        }

        XCTAssertTrue(message.contains("failure"))
    }

    func testStockSummaryEndpointBuildsExpectedURL() {
        let url = ApiEndpoint.stockSummary(symbol: "AAPL", region: "US")
            .makeURL(host: "yh-finance.p.rapidapi.com")

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.path, "/stock/get-fundamentals")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "symbol", value: "AAPL")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "region", value: "US")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "modules", value: "summaryProfile")))
    }

    @MainActor
    func testFetchStocksFiltersInvalidEntriesAndSortsBySymbol() async throws {
        let client = MockHTTPClient()
        client.nextData = Data(
            """
            {
              "marketSummaryAndSparkResponse": {
                "result": [
                  {
                    "symbol": "MSFT",
                    "shortName": "Microsoft Corp.",
                    "fullExchangeName": "NasdaqGS",
                    "regularMarketPrice": { "raw": 421.01 },
                    "regularMarketChangePercent": { "raw": -0.23 }
                  },
                  {
                    "symbol": "",
                    "shortName": "Invalid"
                  },
                  {
                    "symbol": "AAPL",
                    "shortName": "Apple Inc.",
                    "fullExchangeName": "NasdaqGS",
                    "regularMarketPrice": { "raw": 201.23 },
                    "regularMarketChangePercent": { "raw": 1.12 }
                  }
                ]
              }
            }
            """.utf8
        )

        let repository = FinanceRepository(
            config: APIConfiguration(rapidAPIKey: "test-key", rapidAPIHost: "example.com"),
            client: client
        )

        let result = try await repository.fetchStocks()

        XCTAssertEqual(result.map(\.symbol), ["AAPL", "MSFT"])
        XCTAssertEqual(client.requestedURLs.first?.path, "/market/v2/get-summary")
    }

    @MainActor
    func testFetchStocksThrowsNoResultsWhenPayloadIsEmpty() async {
        let client = MockHTTPClient()
        client.nextData = Data(
            """
            {
              "marketSummaryAndSparkResponse": {
                "result": []
              }
            }
            """.utf8
        )

        let repository = FinanceRepository(
            config: APIConfiguration(rapidAPIKey: "test-key", rapidAPIHost: "example.com"),
            client: client
        )

        do {
            _ = try await repository.fetchStocks()
            XCTFail("Expected noResults error")
        } catch let error as APIError {
            guard case .noResults(let message) = error else {
                return XCTFail("Expected noResults error")
            }
            XCTAssertNil(message)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    @MainActor
    func testFetchStockDetailMapsSummaryProfile() async throws {
        let client = MockHTTPClient()
        client.nextData = Data(
            """
            {
              "quoteSummary": {
                "result": [
                  {
                    "summaryProfile": {
                      "name": "Apple Inc.",
                      "sector": "Technology",
                      "industry": "Consumer Electronics",
                      "industryDisp": "Consumer Electronics",
                      "website": "https://www.apple.com",
                      "phone": "1-408-996-1010",
                      "address1": "One Apple Park Way",
                      "city": "Cupertino",
                      "zip": "95014",
                      "country": "United States",
                      "longBusinessSummary": "Designs and sells consumer devices."
                    }
                  }
                ]
              }
            }
            """.utf8
        )

        let repository = FinanceRepository(
            config: APIConfiguration(rapidAPIKey: "test-key", rapidAPIHost: "example.com"),
            client: client
        )

        let detail = try await repository.fetchStockDetail(symbol: "AAPL")

        XCTAssertEqual(detail.symbol, "AAPL")
        XCTAssertEqual(detail.displayName, "Apple Inc.")
        XCTAssertEqual(detail.sector, "Technology")
        XCTAssertEqual(detail.industry, "Consumer Electronics")
        XCTAssertEqual(detail.website, "https://www.apple.com")
        XCTAssertEqual(detail.phone, "1-408-996-1010")
        XCTAssertEqual(detail.address, "One Apple Park Way, Cupertino, 95014, United States")
        XCTAssertEqual(detail.businessSummary, "Designs and sells consumer devices.")
        XCTAssertEqual(client.requestedURLs.first?.path, "/stock/get-fundamentals")
    }

    @MainActor
    func testFetchStockDetailFallsBackToDescriptionWhenLongSummaryMissing() async throws {
        let client = MockHTTPClient()
        client.nextData = Data(
            """
            {
              "quoteSummary": {
                "result": [
                  {
                    "summaryProfile": {
                      "name": "NVIDIA Corporation",
                      "description": "Accelerated computing company."
                    }
                  }
                ]
              }
            }
            """.utf8
        )

        let repository = FinanceRepository(
            config: APIConfiguration(rapidAPIKey: "test-key", rapidAPIHost: "example.com"),
            client: client
        )

        let detail = try await repository.fetchStockDetail(symbol: "NVDA")
        XCTAssertEqual(detail.displayName, "NVIDIA Corporation")
        XCTAssertEqual(detail.businessSummary, "Accelerated computing company.")
    }

    @MainActor
    func testFetchStockDetailSurfacesAPIErrorDescriptionWhenNoResult() async {
        let client = MockHTTPClient()
        client.nextData = Data(
            """
            {
              "quoteSummary": {
                "result": [],
                "error": {
                  "code": "Not Found",
                  "description": "No fundamentals available"
                }
              }
            }
            """.utf8
        )

        let repository = FinanceRepository(
            config: APIConfiguration(rapidAPIKey: "test-key", rapidAPIHost: "example.com"),
            client: client
        )

        do {
            _ = try await repository.fetchStockDetail(symbol: "UNKNOWN")
            XCTFail("Expected noResults error")
        } catch let error as APIError {
            guard case .noResults(let message) = error else {
                return XCTFail("Expected noResults error")
            }
            XCTAssertEqual(message, "No fundamentals available")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
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

private final class MockHTTPClient: HTTPClient {
    var nextData = Data()
    var nextError: Error?
    private(set) var requestedURLs: [URL] = []
    private(set) var requestedHeaders: [[String: String]] = []

    func get(url: URL, headers: [String : String]) async throws -> Data {
        requestedURLs.append(url)
        requestedHeaders.append(headers)

        if let nextError {
            throw nextError
        }

        return nextData
    }
}
