import Foundation

/// Training intensity from Apple Watch / Health heart rate, with optional **heart-rate reserve**
/// (Karvonen-style) when resting HR is known. Zone edges are smoothed so a few BPM differences
/// don't create hard cliffs. Plateau rates (1 / 2 / 1 / 0.5 pt/min) match the prior game balance.
struct HeartRateZones: Equatable {
    enum IntensityModel: Equatable {
        case heartRateReserve
        case maxHeartRatePercentEstimate
    }

    let estimatedMaxHR: Double
    let restingHeartRate: Double?
    let model: IntensityModel

    let zone2: ClosedRange<Double>
    let zone3: ClosedRange<Double>
    let zone4: ClosedRange<Double>

    /// Display alias for settings / copy.
    var maxHR: Double { estimatedMaxHR }

    /// Upper cap for BPM when awarding points beyond the modeled “brisk” band.
    private var highEffortUpperBpm: Double { estimatedMaxHR * 1.10 }

    /// Age- and sex-based max HR **estimate** (Tanaka-style), used as MHR in Karvonen or as zone reference.
    private static func estimatedMaxHeartRate(age: Int, gender: UserGender) -> Double {
        switch gender {
        case .woman:
            return 206 - (0.88 * Double(age))
        case .man:
            return 208 - (0.7 * Double(age))
        }
    }

    /// Computes zone **bpm boundaries**. Uses Karvonen (HRR 60–70 / 70–80 / 80–90 / 90–110%) when
    /// resting HR is present and reserve is large enough; otherwise uses the same percentages of **estimated** max HR.
    static func compute(age: Int, gender: UserGender, restingHeartRate: Double? = nil) -> HeartRateZones {
        let maxHR = estimatedMaxHeartRate(age: age, gender: gender)

        if let rest = restingHeartRate,
           rest >= HeartRateZonePolicy.minimumRestingHR,
           rest <= HeartRateZonePolicy.maximumRestingHR,
           rest < maxHR - HeartRateZonePolicy.minimumHeartRateReserve
        {
            let reserve = maxHR - rest
            func bpm(forHRRFraction fraction: Double) -> Double {
                rest + fraction * reserve
            }
            return HeartRateZones(
                estimatedMaxHR: maxHR,
                restingHeartRate: rest,
                model: .heartRateReserve,
                zone2: bpm(forHRRFraction: 0.60)...bpm(forHRRFraction: 0.70),
                zone3: bpm(forHRRFraction: 0.70)...bpm(forHRRFraction: 0.80),
                zone4: bpm(forHRRFraction: 0.80)...bpm(forHRRFraction: 0.90)
            )
        }

        return HeartRateZones(
            estimatedMaxHR: maxHR,
            restingHeartRate: nil,
            model: .maxHeartRatePercentEstimate,
            zone2: (maxHR * 0.60)...(maxHR * 0.70),
            zone3: (maxHR * 0.70)...(maxHR * 0.80),
            zone4: (maxHR * 0.80)...(maxHR * 0.90)
        )
    }

    func pointsPerMinute(for bpm: Double) -> Double {
        if bpm > highEffortUpperBpm { return 0 }

        let bw = blendHalfWidthBpm()
        let z2L = zone2.lowerBound
        let z3L = zone3.lowerBound
        let z4L = zone4.lowerBound
        let z4U = zone4.upperBound
        let hiCap = highEffortUpperBpm

        // Inter-zone plateaus: tempo (Z3) earns more per minute than easy (Z2) or brisk (Z4),
        // matching common training guidance while keeping prior weekly point scaling.
        let r0: Double = 0
        let rEasy: Double = 1
        let rTempo: Double = 2
        let rBrisk: Double = 1
        let rHard: Double = 0.5
        let rWarm: Double = 0.2

        let warmUpper = z2L - bw
        let warmLower = warmUpper - HeartRateZonePolicy.warmupBandWidthBpm

        if bpm < warmLower {
            return r0
        }
        if bpm < warmUpper {
            let edge = (warmLower + warmUpper) / 2
            let halfWidth = (warmUpper - warmLower) / 2
            return smoothTransition(bpm, edge: edge, halfWidth: halfWidth, low: r0, high: rWarm)
        }
        if bpm < z2L + bw {
            return smoothTransition(bpm, edge: z2L, halfWidth: bw, low: rWarm, high: rEasy)
        }
        if bpm < z3L - bw {
            return rEasy
        }
        if bpm < z3L + bw {
            return smoothTransition(bpm, edge: z3L, halfWidth: bw, low: rEasy, high: rTempo)
        }
        if bpm < z4L - bw {
            return rTempo
        }
        if bpm < z4L + bw {
            return smoothTransition(bpm, edge: z4L, halfWidth: bw, low: rTempo, high: rBrisk)
        }
        if bpm < z4U - bw {
            return rBrisk
        }
        if bpm < z4U + bw {
            return smoothTransition(bpm, edge: z4U, halfWidth: bw, low: rBrisk, high: rHard)
        }
        if bpm < hiCap - bw {
            return rHard
        }
        if bpm <= hiCap {
            return smoothTransition(bpm, edge: hiCap, halfWidth: bw, low: rHard, high: r0)
        }
        return r0
    }

    /// Human-readable note for settings (zones are still estimates; not medical-grade).
    var intensityModelExplanation: String {
        switch model {
        case .heartRateReserve:
            if let rhr = restingHeartRate {
                return "Zones use heart-rate reserve (Karvonen): resting HR from Apple Health (~\(Int(rhr)) bpm) and an age-based max HR estimate (not a lab test)."
            }
            return ""
        case .maxHeartRatePercentEstimate:
            return "No reliable resting HR yet. Zones use percent of max HR until Health has enough resting heart rate data."
        }
    }

    var zoneDescriptions: [(name: String, range: String, points: String)] {
        let bw = blendHalfWidthBpm()
        let warmUpper = zone2.lowerBound - bw
        let warmLower = warmUpper - HeartRateZonePolicy.warmupBandWidthBpm
        let warmRange = "\(Int(warmLower.rounded(.down)))-\(Int(warmUpper.rounded(.down)))"
        let highLo = Int(zone4.upperBound.rounded(.up))
        let highHi = Int(highEffortUpperBpm.rounded(.down))
        let veryHardRange: String
        if highHi > highLo {
            veryHardRange = "\(highLo)-\(highHi) bpm"
        } else {
            veryHardRange = "\(highLo)+ bpm"
        }

        return [
            ("Warm-up", warmRange, "~0.2 pt/min"),
            ("Easy aerobic", "\(Int(zone2.lowerBound))-\(Int(zone2.upperBound))", "~1 pt/min plateau"),
            ("Base building (tempo)", "\(Int(zone3.lowerBound))-\(Int(zone3.upperBound))", "~2 pt/min plateau"),
            ("Brisk", "\(Int(zone4.lowerBound))-\(Int(zone4.upperBound))", "~1 pt/min plateau"),
            ("Very hard", veryHardRange, "~0.5 pt/min, fades out at ceiling"),
        ]
    }

    // MARK: - Private

    private func blendHalfWidthBpm() -> Double {
        let widths = [zone2, zone3, zone4].map { $0.upperBound - $0.lowerBound }
        guard let narrowest = widths.min(), narrowest > 0 else { return 2 }
        return min(HeartRateZonePolicy.preferredBlendHalfWidthBpm, narrowest / 3)
    }

    /// Linear ramp: `low` at `edge - halfWidth`, `high` at `edge + halfWidth`.
    private func smoothTransition(_ bpm: Double, edge: Double, halfWidth: Double, low: Double, high: Double) -> Double {
        let q = (bpm - (edge - halfWidth)) / (2 * halfWidth)
        let t = min(max(q, 0), 1)
        return low + (high - low) * t
    }
}

private enum HeartRateZonePolicy {
    /// Karvonen resting HR must look plausible (HealthKit can be empty or noisy).
    static let minimumRestingHR: Double = 38
    static let minimumHeartRateReserve: Double = 28
    static let maximumRestingHR: Double = 110
    /// ~7 bpm smoothing; shrinks if someone’s zone widths are very narrow.
    static let preferredBlendHalfWidthBpm: Double = 3.5
    /// Narrow sub-zone just below zone 2 to avoid “all or nothing” for easy movement.
    static let warmupBandWidthBpm: Double = 4.0
}
