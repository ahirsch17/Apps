import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case unavailable
    case denied

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Apple Health is not available on this device."
        case .denied: return "Heart rate access is needed to count your movement toward your weekly goal."
        }
    }
}

@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitError.unavailable }
        let heartRate = HKQuantityType(.heartRate)
        let resting = HKQuantityType(.restingHeartRate)
        try await store.requestAuthorization(toShare: [], read: [heartRate, resting])
    }

    /// Matches types we authorize and observe (`HKObserverQuery` + background delivery).
    private static let trackedQuantityTypesForObservers: [HKQuantityType] = [
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
    ]

    /// Enables Health background delivery (`Stoke.entitlements`). Safe to repeat; ignores failures after denial.
    func enableBackgroundDeliveryForTrackedTypesIfPossible() async {
        guard isAvailable else { return }
        for type in Self.trackedQuantityTypesForObservers {
            do {
                try await enableBackgroundDelivery(for: type, frequency: .immediate)
            } catch {}
        }
    }

    /// Caller must retain each query until `invalidate()` to keep receiving callbacks.
    func startObserverQueries(
        sampleTypes: [HKSampleType],
        onSamplesChanged: @escaping @MainActor () -> Void
    ) -> [HKObserverQuery] {
        sampleTypes.map { sampleType in
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { _, completionHandler, _ in
                Task { @MainActor in
                    onSamplesChanged()
                    completionHandler()
                }
            }
            store.execute(query)
            return query
        }
    }

    private func enableBackgroundDelivery(
        for type: HKQuantityType,
        frequency: HKUpdateFrequency
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.enableBackgroundDelivery(for: type, frequency: frequency) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Median resting heart rate across recent Health samples (usually from Apple Watch). Nil if none.
    func medianRestingHeartRateBpm(lookbackDays: Int = 28) async throws -> Double? {
        guard isAvailable else { throw HealthKitError.unavailable }

        let resting = HKQuantityType(.restingHeartRate)
        guard let start = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: Date()) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: resting,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (results as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }

        guard !samples.isEmpty else { return nil }

        let unit = HKUnit.count().unitDivided(by: .minute())
        let bpms = samples.map { $0.quantity.doubleValue(for: unit) }.sorted()
        let mid = bpms.count / 2
        if bpms.count.isMultiple(of: 2) {
            return (bpms[mid - 1] + bpms[mid]) / 2
        }
        return bpms[mid]
    }

    func points(
        from start: Date,
        to end: Date,
        zones: HeartRateZones
    ) async throws -> (points: Double, sampleCount: Int, zoneMinutes: [String: Double]) {
        guard isAvailable else { throw HealthKitError.unavailable }

        let heartRate = HKQuantityType(.heartRate)
        // Default overlap (not strictStartDate) so workout HR samples that span boundaries still count.
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRate,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (results as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }

        var totalPoints: Double = 0
        var z2: Double = 0
        var z3: Double = 0
        var z4: Double = 0
        let unit = HKUnit.count().unitDivided(by: .minute())

        for index in samples.indices {
            let sample = samples[index]
            let bpm = sample.quantity.doubleValue(for: unit)
            let nextStart = index + 1 < samples.count
                ? samples[index + 1].startDate
                : sample.endDate
            let duration = min(nextStart.timeIntervalSince(sample.startDate) / 60.0, 5.0)
            let rate = zones.pointsPerMinute(for: bpm)
            totalPoints += rate * duration
            if zones.zone2.contains(bpm) { z2 += duration }
            if zones.zone3.contains(bpm) { z3 += duration }
            if zones.zone4.contains(bpm) { z4 += duration }
        }

        return (totalPoints, samples.count, ["zone2": z2, "zone3": z3, "zone4": z4])
    }

    func dailyPointsHistory(
        days: Int,
        zones: HeartRateZones,
        calendar: Calendar = .current
    ) async throws -> [Date: Double] {
        var result: [Date: Double] = [:]
        let today = calendar.startOfDay(for: Date())

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayEnd: Date
            if offset == 0 {
                dayEnd = Date()
            } else if let next = calendar.date(byAdding: .day, value: 1, to: day) {
                dayEnd = next
            } else {
                continue
            }
            let dayPoints = try await points(from: day, to: dayEnd, zones: zones)
            result[day] = dayPoints.points
        }
        return result
    }
}
