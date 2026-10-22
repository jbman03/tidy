import XCTest
@testable import TidyCore

final class SignatureTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// Simulates the CMS wrapper bytes around the plist in embedded.mobileprovision.
    func wrap(_ plist: String) -> Data {
        Data([0x30, 0x80, 0x06]) + Data(plist.utf8) + Data([0x00, 0xA0])
    }

    func testParsesExpiration() {
        let p = #"<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>ExpirationDate</key><date>2027-01-01T00:00:00Z</date></dict></plist>"#
        XCTAssertEqual(ProvisioningProfile.expirationDate(from: wrap(p)),
                       ISO8601DateFormatter().date(from: "2027-01-01T00:00:00Z"))
    }

    func testGarbageDataReturnsNil() {
        XCTAssertNil(ProvisioningProfile.expirationDate(from: Data([1, 2, 3])))
        XCTAssertNil(ProvisioningProfile.expirationDate(from: Data("<?xml no end".utf8)))
    }

    func testProfileWithoutExpiration() {
        let p = #"<?xml version="1.0"?><plist version="1.0"><dict><key>Name</key><string>x</string></dict></plist>"#
        XCTAssertNil(ProvisioningProfile.expirationDate(from: wrap(p)))
    }

    func testMissingProfileIsUnknown() {
        XCTAssertEqual(SignatureStatus.evaluate(expiration: nil, now: now), .unknown)
        XCTAssertEqual(SignatureStatus.unknown.message, "Signature: unknown")
    }

    func testBoundaries() {
        let d = 86400.0
        XCTAssertEqual(SignatureStatus.evaluate(expiration: now + 2 * d, now: now), .ok(daysLeft: 2))
        XCTAssertEqual(SignatureStatus.evaluate(expiration: now + 2 * d - 1, now: now), .renewSoon(daysLeft: 2))
        XCTAssertEqual(SignatureStatus.evaluate(expiration: now, now: now), .expired)
        XCTAssertEqual(SignatureStatus.evaluate(expiration: now + 6.5 * d, now: now), .ok(daysLeft: 7))
    }

    func testMessages() {
        XCTAssertEqual(SignatureStatus.ok(daysLeft: 6).message, "Signature renews in 6 days")
        XCTAssertEqual(SignatureStatus.ok(daysLeft: 1).message, "Signature renews in 1 day")
        XCTAssertEqual(SignatureStatus.expired.message, "Signature expired — open SideStore to refresh")
    }
}
