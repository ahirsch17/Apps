import Foundation
import SwiftData
import SwiftUI
import UIKit

@Observable
@MainActor
final class ProgramStore {
    private enum Keys {
        static let onboardingComplete = "onboardingComplete"
        static let age = "age"
        static let gender = "gender"
        static let activityLevel = "activityLevel"
        static let onboardingDate = "onboardingDate"
        static let weekNumber = "weekNumber"
        static let weeklyTarget = "weeklyTarget"
        static let restingHeartRateBpm = "restingHeartRateBpm"
        static let lastRolloverPeriodEnd = "lastRolloverPeriodEnd"
        static let previousWeekEarned = "previousWeekEarned"
        static let previousWeekTarget = "previousWeekTarget"
        static let previousWeekMet = "previousWeekMet"
        static let badgeTilesRequired = "badgeTilesRequired"
        static let badgeTilesCompleted = "badgeTilesCompleted"
        static let badgesEarned = "badgesEarned"
        static let unlockedTileActivities = "unlockedTileActivities"
        static let displayName = "displayName"
        static let consecutiveWeeksMet = "consecutiveWeeksMet"
        static let bestWeekStreak = "bestWeekStreak"
    }

    var onboardingComplete = false
    var age = 0
    var gender: UserGender = .woman
    var activityLevel: ActivityLevel = .sedentary
    var onboardingDate = Date()
    var weekNumber = 1
    var weeklyTarget = 52
    var badgeTilesRequired = 5
    var badgeTilesCompleted = 0
    var badgesEarned = 0
    var unlockedTileActivities = 0
    var displayName = ""
    var consecutiveWeeksMet = 0
    var bestWeekStreak = 0
    /// Median resting HR from Apple Health (cached). Zones use Karvonen when valid.
    var restingHeartRateBpm: Double?

    var zones: HeartRateZones {
        HeartRateZones.compute(age: age, gender: gender, restingHeartRate: restingHeartRateBpm)
    }

    var currentPeriod: WeekPeriod {
        WeekPeriod.current(onboardingDate: onboardingDate)
    }

    var periodTarget: Int {
        periodTarget(for: currentPeriod, week: weekNumber)
    }

    /// Week 1: small bump so the ring means something, still reachable for new users.
    func periodTarget(for period: WeekPeriod, week: Int) -> Int {
        let base = period.targetForWeek(fullTarget: weeklyTarget)
        guard week == 1 else { return base }
        return Int((Double(base) * 1.05).rounded())
    }

    var isPartialWeek: Bool {
        currentPeriod.dayCount < 7
    }

    var goalCaption: String? {
        guard isPartialWeek else { return nil }
        return "Short week through Saturday. Full weeks run Sun to Sat."
    }

    var todayPoints: Double = 0
    var weekPoints: Double = 0
    var dayPointsInPeriod: [Date: Double] = [:]
    var isRefreshing = false
    var refreshError: String?
    var lastRefreshed: Date?
    /// Heart-rate samples read from Health on the most recent successful refresh (all days in period).
    var lastRefreshHeartRateSampleCount: Int = 0

    init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        onboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
        age = defaults.integer(forKey: Keys.age)
        gender = UserGender(rawValue: defaults.string(forKey: Keys.gender) ?? "") ?? .woman
        activityLevel = ActivityLevel(rawValue: defaults.string(forKey: Keys.activityLevel) ?? "") ?? .sedentary
        onboardingDate = defaults.object(forKey: Keys.onboardingDate) as? Date ?? Date()
        let storedWeek = defaults.integer(forKey: Keys.weekNumber)
        weekNumber = storedWeek == 0 ? 1 : storedWeek
        let storedTarget = defaults.integer(forKey: Keys.weeklyTarget)
        weeklyTarget = storedTarget == 0 ? 52 : storedTarget
        let storedTilesRequired = defaults.integer(forKey: Keys.badgeTilesRequired)
        badgeTilesRequired = storedTilesRequired == 0 ? BadgeCycle.tilesRequired(badgeIndex: 0) : storedTilesRequired
        badgeTilesCompleted = max(defaults.integer(forKey: Keys.badgeTilesCompleted), 0)
        badgesEarned = max(defaults.integer(forKey: Keys.badgesEarned), 0)
        unlockedTileActivities = max(defaults.integer(forKey: Keys.unlockedTileActivities), 0)
        displayName = defaults.string(forKey: Keys.displayName) ?? ""
        consecutiveWeeksMet = max(defaults.integer(forKey: Keys.consecutiveWeeksMet), 0)
        bestWeekStreak = max(defaults.integer(forKey: Keys.bestWeekStreak), 0)
        if defaults.object(forKey: Keys.restingHeartRateBpm) != nil {
            let cached = defaults.double(forKey: Keys.restingHeartRateBpm)
            if cached >= 35, cached <= 115 {
                restingHeartRateBpm = cached
            }
        }
    }

    private func persistProfile() {
        let defaults = UserDefaults.standard
        defaults.set(onboardingComplete, forKey: Keys.onboardingComplete)
        defaults.set(age, forKey: Keys.age)
        defaults.set(gender.rawValue, forKey: Keys.gender)
        defaults.set(activityLevel.rawValue, forKey: Keys.activityLevel)
        defaults.set(onboardingDate, forKey: Keys.onboardingDate)
        defaults.set(weekNumber, forKey: Keys.weekNumber)
        defaults.set(weeklyTarget, forKey: Keys.weeklyTarget)
        defaults.set(badgeTilesRequired, forKey: Keys.badgeTilesRequired)
        defaults.set(badgeTilesCompleted, forKey: Keys.badgeTilesCompleted)
        defaults.set(badgesEarned, forKey: Keys.badgesEarned)
        defaults.set(unlockedTileActivities, forKey: Keys.unlockedTileActivities)
        defaults.set(displayName, forKey: Keys.displayName)
        defaults.set(consecutiveWeeksMet, forKey: Keys.consecutiveWeeksMet)
        defaults.set(bestWeekStreak, forKey: Keys.bestWeekStreak)
    }

    func completeOnboarding(
        age: Int,
        gender: UserGender,
        activity: ActivityLevel,
        weeklyTarget: Int,
        displayName: String? = nil
    ) {
        self.age = age
        self.gender = gender
        if let displayName {
            self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.activityLevel = activity
        self.weeklyTarget = weeklyTarget
        self.onboardingDate = Date()
        self.weekNumber = 1
        self.onboardingComplete = true
        self.badgeTilesRequired = BadgeCycle.tilesRequired(badgeIndex: 0)
        self.badgeTilesCompleted = 0
        self.badgesEarned = 0
        self.unlockedTileActivities = 0

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.lastRolloverPeriodEnd)
        defaults.removeObject(forKey: Keys.previousWeekEarned)
        defaults.removeObject(forKey: Keys.previousWeekTarget)
        defaults.removeObject(forKey: Keys.previousWeekMet)
        persistProfile()
    }

    func updateProfile(age: Int, gender: UserGender, displayName: String? = nil) {
        self.age = age
        self.gender = gender
        if let displayName {
            self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        persistProfile()
    }

    func updateDisplayName(_ name: String) {
        displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        persistProfile()
    }

    var greenDaysThisWeek: Int {
        GamificationEngine.greenDayCount(
            period: currentPeriod,
            periodTarget: periodTarget,
            pointsByDay: dayPointsInPeriod,
            weekNumber: weekNumber
        )
    }

    var weekCompletionPercent: Int {
        GamificationEngine.weekCompletionPercent(earned: weekPoints, target: periodTarget)
    }

    func sharePayload() -> StokeSharePayload {
        let period = currentPeriod
        return GamificationEngine.makeSharePayload(
            displayName: displayName,
            weekNumber: weekNumber,
            earned: weekPoints,
            target: periodTarget,
            streak: consecutiveWeeksMet,
            dateRange: WeekHistoryFormatting.dateRange(start: period.start, end: period.end),
            periodEnd: period.end,
            issuedAt: lastRefreshed ?? Date()
        )
    }

    func shareProgressUIImage() -> UIImage? {
        let payload = sharePayload()
        let card = StokeShareCardView(payload: payload)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }

    private var refreshInFlight: Task<Void, Never>?

    func refresh(modelContext: ModelContext) async {
        if let flight = refreshInFlight {
            await flight.value
            return
        }
        let flight = Task { @MainActor in
            await self.executeRefreshPass(modelContext: modelContext)
        }
        refreshInFlight = flight
        await flight.value
        refreshInFlight = nil
    }

    private func executeRefreshPass(modelContext: ModelContext) async {
        isRefreshing = true
        refreshError = nil
        defer { isRefreshing = false }

        do {
            try await HealthKitService.shared.requestAuthorization()
            await refreshRestingHeartRateFromHealth()
            await performRolloverIfNeeded(modelContext: modelContext)
            await reloadPoints(modelContext: modelContext)
            await PaceNudgeService.shared.maybeSendOffPaceNudge(
                weekPoints: weekPoints,
                expectedPoints: expectedPointsSoFar(),
                periodTarget: periodTarget,
                weekNumber: weekNumber,
                period: currentPeriod
            )
            lastRefreshed = Date()
            await HealthKitService.shared.enableBackgroundDeliveryForTrackedTypesIfPossible()
        } catch {
            refreshError = error.localizedDescription
        }
    }

    private func refreshRestingHeartRateFromHealth() async {
        let defaults = UserDefaults.standard
        do {
            if let median = try await HealthKitService.shared.medianRestingHeartRateBpm() {
                restingHeartRateBpm = median
                defaults.set(median, forKey: Keys.restingHeartRateBpm)
            }
        } catch {
            // Keep last cached value so zones stay stable if Health is temporarily unavailable.
        }
    }

    private func reloadPoints(modelContext: ModelContext) async {
        let period = currentPeriod
        let calendar = Calendar.current
        var weekTotal: Double = 0
        var byDay: [Date: Double] = [:]
        var freshQuerySuccessCount = 0
        var freshQueryFailureCount = 0
        var totalHeartRateSamples = 0

        for day in period.datesInPeriod() {
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd: Date
            if calendar.isDateInToday(day) {
                dayEnd = Date()
            } else if let next = calendar.date(byAdding: .day, value: 1, to: dayStart) {
                dayEnd = next
            } else {
                continue
            }

            do {
                let result = try await HealthKitService.shared.points(
                    from: dayStart,
                    to: dayEnd,
                    zones: zones
                )
                freshQuerySuccessCount += 1
                totalHeartRateSamples += result.sampleCount
                byDay[dayStart] = result.points
                weekTotal += result.points
                upsertDayRecord(dayStart: dayStart, points: result.points, context: modelContext)
            } catch {
                freshQueryFailureCount += 1
                if let cached = fetchDayRecord(dayStart: dayStart, context: modelContext) {
                    byDay[dayStart] = cached.points
                    weekTotal += cached.points
                }
            }
        }

        dayPointsInPeriod = byDay
        weekPoints = weekTotal
        todayPoints = byDay[calendar.startOfDay(for: Date())] ?? 0

        lastRefreshHeartRateSampleCount = totalHeartRateSamples

        if freshQuerySuccessCount == 0, freshQueryFailureCount > 0 {
            refreshError = "Could not read Apple Health right now. Showing last saved points."
        } else if freshQueryFailureCount > 0 {
            refreshError = "Some days did not refresh. Pull down to try again."
        } else if freshQuerySuccessCount > 0, totalHeartRateSamples == 0 {
            refreshError =
                "No heart rate in Apple Health this week. Check your Watch sync, then Settings, Health, Apps, Stoke, Heart Rate."
        }
        try? modelContext.save()
    }

    private func performRolloverIfNeeded(modelContext: ModelContext) async {
        let calendar = Calendar.current
        let now = Date()
        var checkDate = onboardingDate

        while true {
            let period = WeekPeriod.current(onboardingDate: onboardingDate, now: checkDate)
            let periodEndDay = calendar.startOfDay(for: period.end)
            guard let dayAfterPeriod = calendar.date(byAdding: .day, value: 1, to: periodEndDay) else { break }

            if now < dayAfterPeriod { break }

            if let lastClosed = UserDefaults.standard.object(forKey: Keys.lastRolloverPeriodEnd) as? Date,
               calendar.startOfDay(for: lastClosed) >= periodEndDay {
                break
            }

            await archivePeriod(period, modelContext: modelContext)
            UserDefaults.standard.set(period.end, forKey: Keys.lastRolloverPeriodEnd)
            checkDate = dayAfterPeriod
        }

        try? modelContext.save()
    }

    private func archivePeriod(_ period: WeekPeriod, modelContext: ModelContext) async {
        let target = periodTarget(for: period, week: weekNumber)
        let earned = await sumPoints(for: period)
        let met = earned >= Double(target)
        let pointsByDay = await dayPointsMap(for: period)
        let greenDays = GamificationEngine.greenDayCount(
            period: period,
            periodTarget: target,
            pointsByDay: pointsByDay,
            weekNumber: weekNumber
        )

        let record = WeekHistoryRecord(
            weekNumber: weekNumber,
            fullWeekTarget: weeklyTarget,
            periodTarget: target,
            pointsEarned: earned,
            startDate: period.start,
            endDate: period.end,
            dayCount: period.dayCount,
            metTarget: met,
            wasRecalibrated: false,
            greenDayCount: greenDays
        )
        modelContext.insert(record)

        let defaults = UserDefaults.standard
        let prevEarned = defaults.object(forKey: Keys.previousWeekEarned) as? Double
        let prevTarget = defaults.object(forKey: Keys.previousWeekTarget) as? Int
        let prevMet = defaults.object(forKey: Keys.previousWeekMet) as? Bool

        var nextTargetAfterWeek: Int?
        var wasRecalibrated = false

        if met {
            consecutiveWeeksMet += 1
            bestWeekStreak = max(bestWeekStreak, consecutiveWeeksMet)

            let result = WeekProgression.nextTarget(
                current: weeklyTarget,
                earned: earned,
                periodTarget: target,
                dayCount: period.dayCount,
                weekNumber: weekNumber,
                previousWeekEarned: prevEarned,
                previousWeekTarget: prevTarget,
                previousWeekMet: prevMet
            )
            weeklyTarget = result.target
            nextTargetAfterWeek = result.target
            wasRecalibrated = result.wasRecalibrated
            record.wasRecalibrated = result.wasRecalibrated
            awardBadgeTileProgress()
            weekNumber += 1
            persistProfile()
        } else {
            consecutiveWeeksMet = 0
            persistProfile()
        }

        let recap = WeekRecapRecord(
            weekNumber: record.weekNumber,
            pointsEarned: earned,
            periodTarget: target,
            metTarget: met,
            greenDayCount: greenDays,
            dayCount: period.dayCount,
            nextWeeklyTarget: nextTargetAfterWeek,
            wasRecalibrated: wasRecalibrated,
            summary: GamificationEngine.recapSummary(
                weekNumber: record.weekNumber,
                earned: earned,
                target: target,
                met: met,
                nextWeeklyTarget: nextTargetAfterWeek,
                wasRecalibrated: wasRecalibrated
            ),
            endDate: period.end
        )
        modelContext.insert(recap)

        defaults.set(earned, forKey: Keys.previousWeekEarned)
        defaults.set(target, forKey: Keys.previousWeekTarget)
        defaults.set(met, forKey: Keys.previousWeekMet)
    }

    private func sumPoints(for period: WeekPeriod) async -> Double {
        let byDay = await dayPointsMap(for: period)
        return byDay.values.reduce(0, +)
    }

    private func dayPointsMap(for period: WeekPeriod) async -> [Date: Double] {
        let calendar = Calendar.current
        var byDay: [Date: Double] = [:]
        for day in period.datesInPeriod() {
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            if let result = try? await HealthKitService.shared.points(from: dayStart, to: dayEnd, zones: zones) {
                byDay[dayStart] = result.points
            }
        }
        return byDay
    }

    private func upsertDayRecord(dayStart: Date, points: Double, context: ModelContext) {
        if let existing = fetchDayRecord(dayStart: dayStart, context: context) {
            existing.points = points
            existing.lastRefreshed = Date()
        } else {
            context.insert(DayPointsRecord(dayStart: dayStart, points: points, lastRefreshed: Date()))
        }
    }

    private func fetchDayRecord(dayStart: Date, context: ModelContext) -> DayPointsRecord? {
        let start = dayStart
        let descriptor = FetchDescriptor<DayPointsRecord>(
            predicate: #Predicate { $0.dayStart == start }
        )
        return try? context.fetch(descriptor).first
    }

    func expectedPointsSoFar(now: Date = Date()) -> Double {
        PaceCurve.expectedPointsSoFar(
            period: currentPeriod,
            periodTarget: periodTarget,
            now: now,
            calendar: Calendar.current
        )
    }

    func paceStatus(now: Date = Date()) -> String {
        PaceMessaging.status(
            weekPoints: weekPoints,
            expectedPoints: expectedPointsSoFar(now: now),
            periodTarget: periodTarget
        )
    }

    func expectedProgressFraction(now: Date = Date()) -> Double {
        guard periodTarget > 0 else { return 0 }
        let expected = expectedPointsSoFar(now: now)
        return min(expected / Double(periodTarget), 1.0)
    }

    /// Outer pace ring: time-based expectation through each calendar day (aligned with HealthKit day buckets).
    func paceRingDisplayFraction(now: Date = Date()) -> Double {
        expectedProgressFraction(now: now)
    }

    /// Inner progress ring: earned points only, 0 until Health data adds to the week.
    func actualProgressFraction() -> Double {
        guard periodTarget > 0 else { return 0 }
        return min(max(weekPoints, 0) / Double(periodTarget), 1.0)
    }

    private func awardBadgeTileProgress() {
        badgeTilesCompleted += 1
        unlockedTileActivities += 1
        if badgeTilesCompleted >= badgeTilesRequired {
            badgesEarned += 1
            badgeTilesCompleted = 0
            badgeTilesRequired = BadgeCycle.tilesRequired(badgeIndex: badgesEarned)
        }
    }
}
