import Foundation
import SwiftData

@Model
final class WeekHistoryRecord {
    var weekNumber: Int
    var fullWeekTarget: Int
    var periodTarget: Int
    var pointsEarned: Double
    var startDate: Date
    var endDate: Date
    var dayCount: Int
    var metTarget: Bool
    var wasRecalibrated: Bool
    var greenDayCount: Int

    init(
        weekNumber: Int,
        fullWeekTarget: Int,
        periodTarget: Int,
        pointsEarned: Double,
        startDate: Date,
        endDate: Date,
        dayCount: Int,
        metTarget: Bool,
        wasRecalibrated: Bool = false,
        greenDayCount: Int = 0
    ) {
        self.weekNumber = weekNumber
        self.fullWeekTarget = fullWeekTarget
        self.periodTarget = periodTarget
        self.pointsEarned = pointsEarned
        self.startDate = startDate
        self.endDate = endDate
        self.dayCount = dayCount
        self.metTarget = metTarget
        self.wasRecalibrated = wasRecalibrated
        self.greenDayCount = greenDayCount
    }
}

@Model
final class DayPointsRecord {
    @Attribute(.unique) var dayStart: Date
    var points: Double
    var lastRefreshed: Date?

    init(dayStart: Date, points: Double, lastRefreshed: Date? = nil) {
        self.dayStart = dayStart
        self.points = points
        self.lastRefreshed = lastRefreshed
    }
}

/// Saved when a week closes — powers recap cards without recomputing history.
@Model
final class WeekRecapRecord {
    var weekNumber: Int
    var pointsEarned: Double
    var periodTarget: Int
    var metTarget: Bool
    var greenDayCount: Int
    var dayCount: Int
    var nextWeeklyTarget: Int?
    var wasRecalibrated: Bool
    var summary: String
    var endDate: Date

    init(
        weekNumber: Int,
        pointsEarned: Double,
        periodTarget: Int,
        metTarget: Bool,
        greenDayCount: Int,
        dayCount: Int,
        nextWeeklyTarget: Int?,
        wasRecalibrated: Bool,
        summary: String,
        endDate: Date
    ) {
        self.weekNumber = weekNumber
        self.pointsEarned = pointsEarned
        self.periodTarget = periodTarget
        self.metTarget = metTarget
        self.greenDayCount = greenDayCount
        self.dayCount = dayCount
        self.nextWeeklyTarget = nextWeeklyTarget
        self.wasRecalibrated = wasRecalibrated
        self.summary = summary
        self.endDate = endDate
    }
}
