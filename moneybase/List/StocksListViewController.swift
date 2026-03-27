import UIKit

final class StocksListViewController: UIViewController {
    private let viewModel: StocksListViewModel
    private let makeDetailViewController: (String) -> UIViewController?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let updatedAtItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchResultsUpdater = self
        controller.searchBar.placeholder = "Search stocks"
        return controller
    }()

    init(
        viewModel: StocksListViewModel,
        makeDetailViewController: @escaping (String) -> UIViewController?
    ) {
        self.viewModel = viewModel
        self.makeDetailViewController = makeDetailViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Stocks"
        view.backgroundColor = .systemBackground
        updatedAtItem.isEnabled = false
        navigationItem.rightBarButtonItem = updatedAtItem
        navigationItem.prompt = nil
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        viewModel.onStateChanged = { [weak self] state in
            self?.render(state)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startAutoRefresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopAutoRefresh()
    }

    private func render(_ state: StocksListState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            updatedAtItem.title = nil
            updateEmptyMessage(nil)
        case .loading:
            activityIndicator.startAnimating()
        case .loaded(let stocks, let updatedAt):
            activityIndicator.stopAnimating()
            tableView.reloadData()

            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            updatedAtItem.title = "Updated: \(formatter.string(from: updatedAt))"

            updateEmptyMessage(stocks.isEmpty ? "No matching stocks found." : nil)
        case .error(let message):
            activityIndicator.stopAnimating()
            updatedAtItem.title = nil
            updateEmptyMessage(message)
        }
    }

    private func updateEmptyMessage(_ message: String?) {
        guard let message, !message.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .callout)
        tableView.backgroundView = label
    }
}

extension StocksListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredStocks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "StockCell")

        guard let stock = viewModel.stock(at: indexPath.row) else {
            return cell
        }

        var content = cell.defaultContentConfiguration()
        content.text = stock.displayName
        content.secondaryText = "\(stock.symbol)\(stock.exchangeName.map { "  •  \($0)" } ?? "")"
        cell.contentConfiguration = content

        let valueLabel: UILabel
        if let label = cell.accessoryView as? UILabel {
            valueLabel = label
        } else {
            valueLabel = UILabel()
            valueLabel.font = .preferredFont(forTextStyle: .subheadline)
            cell.accessoryView = valueLabel
        }

        valueLabel.text = "\(StockFormatting.currency(stock.price))  \(StockFormatting.percentage(stock.changePercent))"
        valueLabel.textColor = StockFormatting.changeColor(for: stock.changePercent)
        valueLabel.sizeToFit()

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard
            let stock = viewModel.stock(at: indexPath.row),
            let detailViewController = makeDetailViewController(stock.symbol)
        else {
            return
        }

        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension StocksListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.updateSearch(text: searchController.searchBar.text ?? "")
    }
}
