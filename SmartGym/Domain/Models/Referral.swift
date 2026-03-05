import Foundation

struct MemberReferralOverview {
    let gymId: String
    let memberId: String
    let pointsBalance: Int64
    let pointValueMinor: Int64
    let currencyCode: String?
    let referralCode: String?

    var moneyValueMajor: Double {
        guard pointValueMinor > 0, pointsBalance > 0 else { return 0 }
        // Assume 2 decimal places for minor units (e.g. cents)
        let totalMinor = Double(pointsBalance * pointValueMinor)
        return totalMinor / 100.0
    }

    var moneyValueDisplay: String {
        let value = moneyValueMajor
        guard value > 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let code = currencyCode {
            formatter.currencyCode = code
        }
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

