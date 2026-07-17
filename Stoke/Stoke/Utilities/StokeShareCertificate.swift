import CryptoKit
import Foundation

struct StokeSharePayload: Equatable {
    let displayName: String
    let weekNumber: Int
    let earned: Int
    let target: Int
    let percent: Int
    let streak: Int
    let dateRange: String
    let periodEndDay: Date
    let issuedAt: Date

    /// Short mark printed on the card (visual only).
    var stampMark: String {
        StokeShareCertificate.stampMark(
            weekNumber: weekNumber,
            earned: earned,
            target: target,
            periodEndDay: periodEndDay
        )
    }
}

enum StokeShareCertificate {
    private static let pepper = "com.hirschengineering.stoke.share.v1"

    static func stampMark(
        weekNumber: Int,
        earned: Int,
        target: Int,
        periodEndDay: Date
    ) -> String {
        let day = Calendar.current.startOfDay(for: periodEndDay)
        let body = "\(weekNumber)|\(earned)|\(target)|\(Int(day.timeIntervalSince1970))"
        let digest = HMAC<SHA256>.authenticationCode(for: Data(body.utf8), using: signingKey)
        return digest.prefix(3).map { String(format: "%02X", $0) }.joined()
    }

    private static var signingKey: SymmetricKey {
        SymmetricKey(data: Data(pepper.utf8))
    }
}
