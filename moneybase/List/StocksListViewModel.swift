import Foundation

enum StocksListState: Equatable {
    case idle
    case loading
    case loaded([StockListItem], Date)
    case error(String)
}

@MainActor
final class StocksListViewModel {
    var onStateChanged: ((StocksListState) -> Void)?

    private(set) var state: StocksListState = .idle {
        didSet { onStateChanged?(state) }
    }

    private(set) var allStocks: [StockListItem] = []
    private(set) var filteredStocks: [StockListItem] = []

    private let repository: StockRepository
    private let refreshInterval: TimeInterval
    private let sleepProvider: AsyncSleepProviding

    private var searchText = ""
    private var lastUpdatedAt: Date?
    private var autoRefreshTask: Task<Void, Never>?

    init(
        repository: StockRepository,
        refreshInterval: TimeInterval = 8.0,
        sleepProvider: AsyncSleepProviding
    ) {
        self.repository = repository
        self.refreshInterval = refreshInterval
        self.sleepProvider = sleepProvider
    }

    convenience init(
        repository: StockRepository,
        refreshInterval: TimeInterval = 8.0
    ) {
        self.init(
            repository: repository,
            refreshInterval: refreshInterval,
            sleepProvider: TaskSleepProvider()
        )
    }

    func startAutoRefresh() {
        guard autoRefreshTask == nil else { return }

        autoRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refresh()

            while !Task.isCancelled {
                do {
                    try await self.sleepProvider.sleep(seconds: self.refreshInterval)
                    if Task.isCancelled { return }
                    await self.refresh()
                } catch {
                    return
                }
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    func refresh() async {
        if allStocks.isEmpty {
            state = .loading
        }

        do {
            allStocks = try await repository.fetchStocks()
            applyFilter()
            lastUpdatedAt = Date()

            if let lastUpdatedAt {
                state = .loaded(filteredStocks, lastUpdatedAt)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func updateSearch(text: String) {
        searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        applyFilter()

        if let lastUpdatedAt {
            state = .loaded(filteredStocks, lastUpdatedAt)
        }
    }

    func stock(at index: Int) -> StockListItem? {
        guard filteredStocks.indices.contains(index) else {
            return nil
        }

        return filteredStocks[index]
    }

    private func applyFilter() {
        guard !searchText.isEmpty else {
            filteredStocks = allStocks
            return
        }

        filteredStocks = allStocks.filter { stock in
            stock.displayName.range(of: searchText, options: .caseInsensitive) != nil ||
            stock.symbol.range(of: searchText, options: .caseInsensitive) != nil
        }
    }
}
