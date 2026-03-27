import UIKit

final class StockDetailViewController: UIViewController {
    private let symbol: String
    private let viewModel: StockDetailViewModel

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let stackView = UIStackView()

    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let sectorLabel = UILabel()
    private let industryLabel = UILabel()
    private let websiteLabel = UILabel()
    private let phoneLabel = UILabel()
    private let addressLabel = UILabel()
    private let summaryLabel = UILabel()

    private var loadTask: Task<Void, Never>?

    init(symbol: String, viewModel: StockDetailViewModel) {
        self.symbol = symbol
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = symbol
        view.backgroundColor = .systemBackground
        setupUI()

        viewModel.onStateChanged = { [weak self] state in
            self?.render(state)
        }

        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.viewModel.load(symbol: self.symbol)
        }
    }

    deinit {
        loadTask?.cancel()
    }

    private func setupUI() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12

        [nameLabel, symbolLabel, sectorLabel, industryLabel, websiteLabel, phoneLabel, addressLabel, summaryLabel].forEach { label in
            label.numberOfLines = 0
            stackView.addArrangedSubview(label)
        }

        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.textColor = .label

        symbolLabel.font = .preferredFont(forTextStyle: .subheadline)
        symbolLabel.textColor = .secondaryLabel

        [sectorLabel, industryLabel, websiteLabel, phoneLabel, addressLabel, summaryLabel].forEach { label in
            label.font = .preferredFont(forTextStyle: .body)
            label.textColor = .label
        }

        summaryLabel.font = .preferredFont(forTextStyle: .callout)
        summaryLabel.textColor = .secondaryLabel

        view.addSubview(stackView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func render(_ state: StockDetailState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            stackView.isHidden = false
        case .loading:
            activityIndicator.startAnimating()
            stackView.isHidden = true
        case .loaded(let detail):
            activityIndicator.stopAnimating()
            stackView.isHidden = false

            nameLabel.text = detail.displayName
            symbolLabel.text = detail.symbol
            sectorLabel.text = "Sector: \(detail.sector ?? "--")"
            industryLabel.text = "Industry: \(detail.industry ?? "--")"
            websiteLabel.text = "Website: \(detail.website ?? "--")"
            phoneLabel.text = "Phone: \(detail.phone ?? "--")"
            addressLabel.text = "Address: \(detail.address ?? "--")"
            summaryLabel.text = "About: \(detail.businessSummary ?? "--")"
        case .error(let message):
            activityIndicator.stopAnimating()
            stackView.isHidden = false

            nameLabel.text = "Unable to load stock details"
            symbolLabel.text = symbol
            sectorLabel.text = message
            industryLabel.text = nil
            websiteLabel.text = nil
            phoneLabel.text = nil
            addressLabel.text = nil
            summaryLabel.text = nil
        }
    }
}
