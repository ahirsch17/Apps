import Foundation
import Combine

enum RacePhase: Equatable {
    case idle
    case buffering(stationIndex: Int, secondsRemaining: Int)
    case pacing(stationIndex: Int)
    case redAlert(stationIndex: Int)
    case finished
}

/// Always the same shape: big title line + smaller subtitle line.
struct HandoffSlot: Equatable {
    let title: String
    let subtitle: String
}

enum EstimateStatus: Equatable {
    case ahead
    case onPace
    case behind
}

@MainActor
final class RaceEngine: ObservableObject {
    @Published private(set) var phase: RacePhase = .idle
    @Published private(set) var centerText: String = "Ready"
    @Published private(set) var stationTitle: String = "Run 1K"
    @Published private(set) var estimateText: String = ""
    @Published private(set) var estimateStatus: EstimateStatus = .onPace
    @Published private(set) var activeSlot: HandoffSlot?
    @Published private(set) var upcomingSlot: HandoffSlot?
    @Published private(set) var isFlashingRed = false

    private let stations = RacePlan.stations
    private let keepAlive = WorkoutKeepAlive()
    private var estimatedFinishSeconds: TimeInterval = RacePlan.targetFinishSeconds
    private var phaseStartDate: Date?
    private var bufferDuration: TimeInterval = 0
    private var timer: AnyCancellable?
    private var inputLockedUntil: Date = .distantPast

    init() {
        estimateText = Self.formatEstimate(estimatedFinishSeconds)
        estimateStatus = .onPace
        stationTitle = stations[0].shortName
        activeSlot = nil
        upcomingSlot = nil
        startTicker()
    }

    func handleTap() {
        guard Date() >= inputLockedUntil else { return }

        switch phase {
        case .idle:
            keepAlive.start()
            beginPacing(stationIndex: 0)
            lockInput(for: 1.0)

        case .buffering:
            break

        case .pacing(let index), .redAlert(let index):
            advanceFromStation(index)
            lockInput(for: 1.2)

        case .finished:
            break
        }
    }

    private func lockInput(for seconds: TimeInterval) {
        inputLockedUntil = Date().addingTimeInterval(seconds)
    }

    // MARK: - Transitions

    private func advanceFromStation(_ index: Int) {
        applyPaceDelta(for: index)

        let nextIndex = index + 1
        guard nextIndex < stations.count else {
            finishRace()
            return
        }
        let finished = stations[index]
        let duration = finished.isRun ? RacePlan.bufferAfterRun : RacePlan.bufferAfterStation
        beginBuffer(for: nextIndex, duration: duration)
    }

    private func applyPaceDelta(for index: Int) {
        guard let start = phaseStartDate else { return }
        let actual = Date().timeIntervalSince(start)
        let planned = stations[index].targetDurationSeconds
        estimatedFinishSeconds += actual - planned
        estimateText = Self.formatEstimate(estimatedFinishSeconds)
        refreshEstimateStatus()
    }

    private func refreshEstimateStatus() {
        let delta = estimatedFinishSeconds - RacePlan.targetFinishSeconds
        if delta < -2 {
            estimateStatus = .ahead
        } else if delta > 2 {
            estimateStatus = .behind
        } else {
            estimateStatus = .onPace
        }
    }

    private func beginBuffer(for stationIndex: Int, duration: TimeInterval) {
        isFlashingRed = false
        bufferDuration = duration
        phaseStartDate = Date()
        let secs = max(1, Int(ceil(duration)))
        phase = .buffering(stationIndex: stationIndex, secondsRemaining: secs)
        let station = stations[stationIndex]
        stationTitle = station.shortName
        centerText = "\(secs)s"
        refreshAssignment(stationIndex: stationIndex, progress: 0)
    }

    private func beginPacing(stationIndex: Int) {
        isFlashingRed = false
        phaseStartDate = Date()
        phase = .pacing(stationIndex: stationIndex)
        let station = stations[stationIndex]
        stationTitle = station.shortName
        centerText = ProgressFormatting.format(0, unit: station.unit)
        refreshAssignment(stationIndex: stationIndex, progress: 0)
    }

    private func enterRedAlert(stationIndex: Int) {
        phase = .redAlert(stationIndex: stationIndex)
        isFlashingRed = true
        let station = stations[stationIndex]
        stationTitle = station.shortName
        centerText = ProgressFormatting.format(station.targetTotalWork, unit: station.unit)
        refreshAssignment(stationIndex: stationIndex, progress: station.targetTotalWork)
    }

    private func finishRace() {
        phase = .finished
        isFlashingRed = false
        stationTitle = "Finish"
        centerText = "Done"
        activeSlot = nil
        upcomingSlot = nil
        phaseStartDate = nil
        keepAlive.stop()
    }

    // MARK: - Ticker

    private func startTicker() {
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tick(now: now)
            }
    }

    private func tick(now: Date) {
        switch phase {
        case .idle, .finished:
            isFlashingRed = false

        case .buffering(let stationIndex, _):
            guard let start = phaseStartDate else { return }
            let remaining = bufferDuration - now.timeIntervalSince(start)
            if remaining <= 0 {
                beginPacing(stationIndex: stationIndex)
            } else {
                let secs = max(1, Int(ceil(remaining)))
                phase = .buffering(stationIndex: stationIndex, secondsRemaining: secs)
                centerText = "\(secs)s"
                refreshAssignment(stationIndex: stationIndex, progress: 0)
            }

        case .pacing(let stationIndex):
            guard let start = phaseStartDate else { return }
            let station = stations[stationIndex]
            let elapsed = now.timeIntervalSince(start)
            if elapsed >= station.targetDurationSeconds {
                enterRedAlert(stationIndex: stationIndex)
                return
            }
            let rate = station.targetTotalWork / station.targetDurationSeconds
            let progress = min(station.targetTotalWork, elapsed * rate)
            centerText = ProgressFormatting.format(progress, unit: station.unit)
            refreshAssignment(stationIndex: stationIndex, progress: progress)

        case .redAlert:
            isFlashingRed = Int(now.timeIntervalSince1970 * 4) % 2 == 0
        }
    }

    private static func formatEstimate(_ seconds: TimeInterval) -> String {
        ProgressFormatting.formatClock(max(0, seconds))
    }

    // MARK: - Handoff

    private func refreshAssignment(stationIndex: Int, progress: Double) {
        let slots = handoffSlots(stationIndex: stationIndex, progress: progress)
        activeSlot = slots.active
        upcomingSlot = slots.upcoming
    }

    private func handoffSlots(stationIndex: Int, progress: Double) -> (active: HandoffSlot?, upcoming: HandoffSlot?) {
        guard stationIndex < stations.count else { return (nil, nil) }
        let station = stations[stationIndex]

        // Runs: single NEXT chip = station name only (no person mixed in).
        if station.resolvedSegments.isEmpty {
            guard stationIndex + 1 < stations.count else { return (nil, nil) }
            let next = stations[stationIndex + 1]
            return (nil, HandoffSlot(title: next.shortName, subtitle: ""))
        }

        // Split station: ON = person+meters, THEN = next person+meters (or next station on last chunk).
        let activeIndex: Int
        if case .buffering = phase {
            activeIndex = 0
        } else {
            activeIndex = activeSegmentIndex(station: station, progress: progress)
        }

        let active = turnSlot(station: station, segmentIndex: activeIndex)
        let nextIndex = activeIndex + 1
        if nextIndex < station.resolvedSegments.count {
            return (active, turnSlot(station: station, segmentIndex: nextIndex))
        }
        if stationIndex + 1 < stations.count {
            return (active, HandoffSlot(title: stations[stationIndex + 1].shortName, subtitle: ""))
        }
        return (active, nil)
    }

    private func activeSegmentIndex(station: Station, progress: Double) -> Int {
        let thresholds = station.segmentStartThresholds
        var activeIndex = 0
        for (i, threshold) in thresholds.enumerated() where progress + 0.0001 >= threshold {
            activeIndex = i
        }
        return min(activeIndex, max(0, station.resolvedSegments.count - 1))
    }

    private func turnSlot(station: Station, segmentIndex: Int) -> HandoffSlot {
        let segment = station.resolvedSegments[segmentIndex]
        let amount = ProgressFormatting.formatSegmentAmount(segment, unit: station.unit)
        return HandoffSlot(title: segment.athlete, subtitle: amount)
    }
}
