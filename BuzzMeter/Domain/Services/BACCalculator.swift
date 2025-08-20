//
//  BACCalculator.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/19/25.
//
import Foundation

struct BACCalculator {

    static func bac(at date: Date, session: DrinkSession, user: UserProfile) -> Double {
        guard let firstDrinkTime = session.entries.map(\.startedAt).min() else { return 0 }

        // Total grams consumed up to `date` (naive: fully absorbed immediately)
        let gramsConsumed = session.entries
            .filter { $0.startedAt <= date }
            .reduce(into: 0.0) { $0 += $1.drink.alcoholGrams }

        // Widmark factor r by sex
        let r = user.alcoholDistributionRatio

        // Distribution term: alcohol consumed in grams / (weight in grams * r)
        // convert to % by * 100
        let distribution = gramsConsumed / (user.weightKg * 1000 * r) * 100

        // Elimination: beta * hours since first drink
        let hoursSinceStart = max(date.timeIntervalSince(firstDrinkTime) / 3600.0, 0)
        let beta = 0.015
        let eliminated = beta * hoursSinceStart

        // %BAC cannot be negative
        return max(distribution - eliminated, 0)
    }
    

    static func projectedBAC(
        at date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool
    ) -> Double {
        // No drinks → 0
        guard let firstStart = session.entries.map(\.startedAt).min() else { return 0 }

        // Absorption params (rough population averages)
        // Fasted: t_lag ≈ 10–15 min, k_a ≈ 1.0 h⁻¹ (half‑life ~40 min)
        // Fed:    t_lag ≈ 20–30 min, k_a ≈ 0.4–0.6 h⁻¹
        let tLagSeconds: TimeInterval = eaten ? 25 * 60 : 12 * 60
        let kaPerHour: Double = eaten ? 0.5 : 1.0
        let kaPerSecond = kaPerHour / 3600.0

    
        var absorbedGrams = 0.0

        for entry in session.entries {
            // Ignore drinks that start in the future relative to `date`
            guard entry.startedAt <= date else { continue }

            let A0 = entry.drink.alcoholGrams
            let t = date.timeIntervalSince(entry.startedAt)

            if t <= tLagSeconds {
                // Still in lag phase → no absorption yet from this drink
                continue
            } else {
                // First‑order absorption after lag: A_abs = A0 * (1 − e^(−k_a * Δt))
                let dt = t - tLagSeconds                      // seconds since end of lag
                let fractionAbsorbed = 1.0 - exp(-kaPerSecond * dt)
                let absorbed = min(A0 * fractionAbsorbed, A0) // cap at full drink
                absorbedGrams += absorbed
            }
        }

        // 2) Distribution (Widmark)
        let r = user.alcoholDistributionRatio
        let bodyMassGrams = max(user.weightKg, 1) * 1000.0
        let bacGross = (absorbedGrams / (bodyMassGrams * r)) * 100.0  // convert to %BAC

        // 3) Elimination (population avg. β ≈ 0.015 %BAC/hour)
        // Start eliminating once alcohol plausibly reaches blood after the first drink’s lag.
        let beta = 0.015
        let hoursSinceAbsorptionStart = max((date.timeIntervalSince(firstStart) - tLagSeconds) / 3600.0, 0)
        let eliminated = beta * hoursSinceAbsorptionStart

        // 4) Net BAC (never negative)
        return max(bacGross - eliminated, 0)
    }
    
    
    static func decaySeries(from start: Date,
                            initialBAC: Double,
                            stepMinutes: Int = 5,
                            betaPerHour: Double = 0.015) -> [(Date, Double)] {
        guard initialBAC > 0 else { return [(start, 0)] }

        var t = start
        var bac = initialBAC
        var out: [(Date, Double)] = [(t, bac)]
        let dt = TimeInterval(stepMinutes * 60)
        let dropPerStep = betaPerHour * (Double(stepMinutes) / 60.0)

        while bac > 0 {
            t = t.addingTimeInterval(dt)
            bac = max(bac - dropPerStep, 0)
            out.append((t, bac))
        }
        return out
    }

    static func timeToZeroHours(from bac: Double, betaPerHour: Double = 0.015) -> Double {
        guard bac > 0 else { return 0 }
        return bac / max(betaPerHour, 1e-9)
    }
    
    static func description(for bac: Double) -> String {
            switch bac {
            case ..<0.02:
                return "Sober"

            case 0.02..<0.05:
                return "Mild Effects (Lightheaded)"

            case 0.05..<0.08:
                return "Buzzed"

            case 0.08..<0.11:
                return "Legally Intoxicated"

            case 0.11..<0.16:
                return "Drunk"

            case 0.16..<0.20:
                return "Very Drunk"

            case 0.20..<0.25:
                return "Dazed and Confused"

            case 0.25..<0.31:
                return "Stupor"

            default:
                return "Coma"
            }
        }
}
