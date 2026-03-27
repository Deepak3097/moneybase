import UIKit

enum StockFormatting {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter
    }()

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func currency(_ value: Double?) -> String {
        guard let value else { return "--" }
        return currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    static func percentage(_ value: Double?) -> String {
        guard let value else { return "--" }
        return percentageFormatter.string(from: NSNumber(value: value / 100.0)) ?? String(format: "%.2f%%", value)
    }

    static func changeColor(for percent: Double?) -> UIColor {
        guard let percent else { return .secondaryLabel }
        if percent > 0 { return .systemGreen }
        if percent < 0 { return .systemRed }
        return .secondaryLabel
    }
}
