import Foundation

enum WorkUnit: Equatable {
    case meters
    case kilometers
    case reps
    case lengths
}

struct Segment: Equatable {
    let athlete: String
    /// Work amount in the station's unit (used for pacing thresholds).
    let amount: Double
    /// Optional amount shown in the Next preview (e.g. "5" for BBJ while amount is in lengths).
    let labelAmount: Double?

    init(athlete: String, amount: Double, labelAmount: Double? = nil) {
        self.athlete = athlete
        self.amount = amount
        self.labelAmount = labelAmount
    }
}

struct Station: Equatable, Identifiable {
    let id: Int
    let name: String
    let shortName: String
    let isRun: Bool
    /// Pure pacing duration after the buffer ends.
    let targetDurationSeconds: TimeInterval
    let targetTotalWork: Double
    let unit: WorkUnit
    /// Ordered sub-segments; if `repeats` is true, cycle until total work is covered.
    let segments: [Segment]
    let repeats: Bool

    /// Expanded segment list covering the full station work.
    var resolvedSegments: [Segment] {
        guard !segments.isEmpty else { return [] }
        if !repeats {
            return segments
        }
        var result: [Segment] = []
        var covered = 0.0
        var index = 0
        while covered < targetTotalWork - 0.0001 {
            let segment = segments[index % segments.count]
            result.append(segment)
            covered += segment.amount
            index += 1
            if index > 10_000 { break }
        }
        return result
    }

    /// Cumulative work thresholds at which each segment begins (first is 0).
    var segmentStartThresholds: [Double] {
        let resolved = resolvedSegments
        guard !resolved.isEmpty else { return [] }
        var thresholds: [Double] = [0]
        var cumulative = 0.0
        for segment in resolved.dropLast() {
            cumulative += segment.amount
            thresholds.append(cumulative)
        }
        return thresholds
    }
}

enum RacePlan {
    /// Runs open immediately (no lead-in buffer). Buffers only between stations.
    /// 8:30/mi runs + stations ≈ 1:19:31.
    static let targetFinishSeconds: TimeInterval = 1 * 3600 + 19 * 60 + 31

    static let bufferAfterRun: TimeInterval = 20
    static let bufferAfterStation: TimeInterval = 15

    /// 1K @ 8:30/mi ≈ 5:17/km.
    private static let runPaceSeconds: TimeInterval = 5 * 60 + 17

    static let stations: [Station] = [
        Station(
            id: 1,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 2,
            name: "Ski Erg",
            shortName: "Ski",
            isRun: false,
            targetDurationSeconds: 5 * 60 + 5,
            targetTotalWork: 1000,
            unit: .meters,
            segments: [
                Segment(athlete: "Ty", amount: 275),
                Segment(athlete: "Alex", amount: 450),
                Segment(athlete: "Ty", amount: 275)
            ],
            repeats: false
        ),
        Station(
            id: 3,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 4,
            name: "Sled Push",
            shortName: "Push",
            isRun: false,
            targetDurationSeconds: 2 * 60 + 50,
            targetTotalWork: 4.0,
            unit: .lengths,
            segments: [
                Segment(athlete: "Alex", amount: 0.5),
                Segment(athlete: "Ty", amount: 1.0),
                Segment(athlete: "Alex", amount: 0.75),
                Segment(athlete: "Ty", amount: 1.25),
                Segment(athlete: "Alex", amount: 0.5)
            ],
            repeats: false
        ),
        Station(
            id: 5,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 6,
            name: "Sled Pull",
            shortName: "Pull",
            isRun: false,
            targetDurationSeconds: 4 * 60,
            targetTotalWork: 4.0,
            unit: .lengths,
            // Ty (bigger) starts every new 12.5m length; Alex finishes each lane.
            segments: [
                Segment(athlete: "Ty", amount: 0.75),
                Segment(athlete: "Alex", amount: 0.25),
                Segment(athlete: "Ty", amount: 0.75),
                Segment(athlete: "Alex", amount: 0.25),
                Segment(athlete: "Ty", amount: 0.75),
                Segment(athlete: "Alex", amount: 0.25),
                Segment(athlete: "Ty", amount: 0.75),
                Segment(athlete: "Alex", amount: 0.25)
            ],
            repeats: false
        ),
        Station(
            id: 7,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        // Official BBJ is 80m; Alex/Ty alternate 5m.
        Station(
            id: 8,
            name: "Burpee Broad Jumps",
            shortName: "BBJ",
            isRun: false,
            targetDurationSeconds: 4 * 60 + 50,
            targetTotalWork: 80,
            unit: .meters,
            segments: [
                Segment(athlete: "Alex", amount: 5),
                Segment(athlete: "Ty", amount: 5)
            ],
            repeats: true
        ),
        Station(
            id: 9,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 10,
            name: "Row",
            shortName: "Row",
            isRun: false,
            targetDurationSeconds: 4 * 60 + 30,
            targetTotalWork: 1000,
            unit: .meters,
            segments: [
                // Alex opens so Ty can catch breath off the run; Ty takes the bulk; Ty closes.
                Segment(athlete: "Alex", amount: 200),
                Segment(athlete: "Ty", amount: 400),
                Segment(athlete: "Alex", amount: 200),
                Segment(athlete: "Ty", amount: 200)
            ],
            repeats: false
        ),
        Station(
            id: 11,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 12,
            name: "Farmers Carry",
            shortName: "Farmers",
            isRun: false,
            targetDurationSeconds: 2 * 60 + 50,
            targetTotalWork: 200,
            unit: .meters,
            segments: [
                Segment(athlete: "Alex", amount: 70),
                Segment(athlete: "Ty", amount: 130)
            ],
            repeats: false
        ),
        Station(
            id: 13,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 14,
            name: "Lunges",
            shortName: "Lunges",
            isRun: false,
            targetDurationSeconds: 4 * 60 + 45,
            targetTotalWork: 100,
            unit: .meters,
            segments: [
                Segment(athlete: "Alex", amount: 7),
                Segment(athlete: "Ty", amount: 10)
            ],
            repeats: true
        ),
        Station(
            id: 15,
            name: "Run 1K",
            shortName: "Run 1K",
            isRun: true,
            targetDurationSeconds: runPaceSeconds,
            targetTotalWork: 1.0,
            unit: .kilometers,
            segments: [],
            repeats: false
        ),
        Station(
            id: 16,
            name: "Wall Balls",
            shortName: "Wall Balls",
            isRun: false,
            targetDurationSeconds: 4 * 60,
            targetTotalWork: 100,
            unit: .reps,
            segments: [
                Segment(athlete: "Ty", amount: 20),
                Segment(athlete: "Alex", amount: 20),
                Segment(athlete: "Ty", amount: 20),
                Segment(athlete: "Alex", amount: 20),
                Segment(athlete: "Ty", amount: 20)
            ],
            repeats: false
        )
    ]
}

enum ProgressFormatting {
    static func format(_ value: Double, unit: WorkUnit) -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.2fK", value)
        case .meters:
            return "\(Int(value.rounded(.down)))m"
        case .reps:
            return "\(Int(value.rounded(.down)))"
        case .lengths:
            return formatLengths(value)
        }
    }

    static func formatSegmentAmount(_ segment: Segment, unit: WorkUnit) -> String {
        if let label = segment.labelAmount {
            if label == floor(label) {
                return "\(Int(label))"
            }
            return String(format: "%g", label)
        }
        switch unit {
        case .kilometers:
            return String(format: "%.2fK", segment.amount)
        case .meters:
            return "\(Int(segment.amount))m"
        case .reps:
            return "\(Int(segment.amount))"
        case .lengths:
            return String(format: "%gL", segment.amount)
        }
    }

    static func formatLengths(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.001 {
            return String(format: "%.0fL", value.rounded())
        }
        let tenths = (value * 10).rounded() / 10
        if abs(value - tenths) < 0.001 {
            return String(format: "%.1fL", tenths)
        }
        return String(format: "%.2fL", value)
    }

    static func formatRange(from start: Double, to end: Double, unit: WorkUnit) -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.2f–%.2fK", start, end)
        case .meters:
            return "\(Int(start.rounded()))–\(Int(end.rounded()))m"
        case .reps:
            return "\(Int(start.rounded()))–\(Int(end.rounded()))"
        case .lengths:
            return "\(formatLengths(start).replacingOccurrences(of: "L", with: ""))–\(formatLengths(end))"
        }
    }

    static func formatClock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
