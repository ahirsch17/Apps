import Foundation

struct HealthDataAssessment {
    let daysQueried: Int
    let daysWithHeartRate: Int
    let hasAnyData: Bool
    let isReliable: Bool

    static let minimumReliableDays = 4

    static func analyze(dailyPoints: [Date: Double], daysQueried: Int) -> HealthDataAssessment {
        let daysWithData = dailyPoints.values.filter { $0 > 0.5 }.count
        let hasAny = daysWithData > 0
        let reliable = daysWithData >= minimumReliableDays
        return HealthDataAssessment(
            daysQueried: daysQueried,
            daysWithHeartRate: daysWithData,
            hasAnyData: hasAny,
            isReliable: reliable
        )
    }

    var onboardingNotice: String? {
        if !hasAnyData {
            return "No heart rate in Apple Health yet. Using your answers."
        }
        if !isReliable {
            return "Limited Health history. Using your answers."
        }
        return nil
    }
}
