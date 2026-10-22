import Foundation
import TidyCore

/// The signature status of the running app, from the profile SideStore embeds at install.
enum SigningInfo {
    static func current(now: Date = .now) -> SignatureStatus {
        let expiration = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap(ProvisioningProfile.expirationDate(from:))
        return SignatureStatus.evaluate(expiration: expiration, now: now)
    }
}
