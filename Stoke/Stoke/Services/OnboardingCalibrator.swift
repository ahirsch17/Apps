import Foundation

enum OnboardingCalibrator {
    private static let minimumTarget = 40
    private static let maximumInitialTarget = 125

    static func suggestedWeeklyTarget(
        age: Int,
        activityLevel: ActivityLevel,
        healthDailyAverages: [Double],
        healthDataReliable: Bool
    ) -> Int {
        let questionnaireBase = activityLevel.suggestedWeeklyTarget + ageAdjustment(age: age)

        guard healthDataReliable else {
            return clamp(questionnaireBase)
        }

        let nonZeroDays = healthDailyAverages.filter { $0 > 0.5 }
        guard nonZeroDays.count >= HealthDataAssessment.minimumReliableDays else {
            return clamp(questionnaireBase)
        }

        let averageDaily = nonZeroDays.reduce(0, +) / Double(nonZeroDays.count)
        let projectedWeekly = averageDaily * 7
        let healthBased = Int((projectedWeekly * 0.85).rounded())
        let blended = Int((Double(questionnaireBase) * 0.45 + Double(healthBased) * 0.55).rounded())
        return clamp(max(blended, questionnaireBase - 8))
    }

    static func clamp(_ value: Int) -> Int {
        min(max(value, minimumTarget), maximumInitialTarget)
    }

    private static func ageAdjustment(age: Int) -> Int {
        switch age {
        case ..<30: return 4
        case 30..<45: return 0
        case 45..<60: return -4
        case 60..<70: return -7
        default: return -10
        }
    }
}
