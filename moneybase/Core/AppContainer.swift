import UIKit

final class AppContainer {
    private let repository: StockRepository

    init() {
        do {
            let config = try APIConfiguration()
            repository = FinanceRepository(config: config, client: URLSessionHTTPClient())
        } catch {
            repository = FailingRepository(error: error)
        }
    }

    func makeRootViewController() -> UIViewController {
        let viewModel = StocksListViewModel(repository: repository)
        let listViewController = StocksListViewController(viewModel: viewModel, makeDetailViewController: { [weak self] symbol in
                self?.makeDetailViewController(symbol: symbol)
            }
        )

        return UINavigationController(rootViewController: listViewController)
    }

    private func makeDetailViewController(symbol: String) -> UIViewController {
        let viewModel = StockDetailViewModel(repository: repository)
        return StockDetailViewController(symbol: symbol, viewModel: viewModel)
    }
}
