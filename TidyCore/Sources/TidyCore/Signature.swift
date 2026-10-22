import Foundation

/// Reads the signing profile SideStore embeds in the app bundle.
public enum ProvisioningProfile {
    /// Extracts `ExpirationDate` from `embedded.mobileprovision` bytes: the plist sits inside a
    /// CMS envelope, so we slice from `<?xml` through `</plist>` and parse that.
    public static func expirationDate(from data: Data) -> Date? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex)
        else { return nil }
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil),
              let dict = plist as? [String: Any]
        else { return nil }
        return dict["ExpirationDate"] as? Date
    }
}

/// How close the app's 7-day free signature is to running out.
public enum SignatureStatus: Equatable, Sendable {
    case ok(daysLeft: Int)
    case renewSoon(daysLeft: Int)
    case expired
    case unknown

    private static let day: TimeInterval = 86400
    private static let renewSoonThreshold: TimeInterval = 2 * day

    public static func evaluate(expiration: Date?, now: Date) -> SignatureStatus {
        guard let expiration else { return .unknown }
        let secondsLeft = expiration.timeIntervalSince(now)
        if secondsLeft <= 0 { return .expired }
        let daysLeft = Int((secondsLeft / day).rounded(.up))  // matches SideStore's "7 DAYS" counter
        return secondsLeft < renewSoonThreshold ? .renewSoon(daysLeft: daysLeft) : .ok(daysLeft: daysLeft)
    }

    public var message: String {
        switch self {
        case .ok(let n): n == 1 ? "Signature renews in 1 day" : "Signature renews in \(n) days"
        case .renewSoon: "Signature expires soon — open SideStore to refresh"
        case .expired: "Signature expired — open SideStore to refresh"
        case .unknown: "Signature: unknown"
        }
    }

    public var needsAttention: Bool {
        switch self {
        case .renewSoon, .expired: true
        case .ok, .unknown: false
        }
    }
}
