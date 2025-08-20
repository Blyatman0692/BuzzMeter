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
    
    static func timePrediction() {}
    
    
    static func description(for bac: Double) -> String {
        let level = BuzzLevel.fromBAC(bac)
        return level.displayName
    }
}

extension BACCalculator {
    /// Earliest Date at which projected BAC will be <= targetBAC, from `date`.
    /// Returns `nil` if it doesn't drop to target within `maxHours`.
    static func earliestTime(
        toReach targetBAC: Double,
        from date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool,
        maxHours: Double = 24,
        toleranceSeconds: TimeInterval = 30
    ) -> Date? {
        func g(_ dt: TimeInterval) -> Double {
            projectedBAC(
                at: date.addingTimeInterval(dt),
                session: session,
                user: user,
                eaten: eaten
            ) - targetBAC
        }

        // If we're already at/below the target, return now.
        if g(0) <= 0 { return date }

        // Exponential search to bracket the root: find hi with g(hi) <= 0
        var lo: TimeInterval = 0
        var hi: TimeInterval = 15 * 60  // start with 15 minutes
        let maxT = maxHours * 3600

        while g(hi) > 0, hi < maxT {
            lo = hi
            hi = min(hi * 2, maxT)
            if hi == lo { break }
        }

        // If even at max horizon we’re still above target → give up.
        if g(hi) > 0 { return nil }

        // Bisection on [lo, hi]
        var left = lo
        var right = hi
        while right - left > toleranceSeconds {
            let mid = 0.5 * (left + right)
            if g(mid) > 0 {
                left = mid
            } else {
                right = mid
            }
        }

        return date.addingTimeInterval(right)
    }

    /// Conservative: earliest time you can take `nextDrink` and remain <= targetBAC
    /// assuming *instant absorption* of the next drink (worst-case jump).
    static func waitUntilSafeForNextDrink(
        targetBAC: Double,
        nextDrink: Drink,
        from date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool,
        maxHours: Double = 24,
        toleranceSeconds: TimeInterval = 30
    ) -> Date? {
        // Worst-case jump from the next drink if absorbed instantly at take time.
        let r = user.alcoholDistributionRatio
        let bodyMassGrams = max(user.weightKg, 1) * 1000.0
        let deltaNextWorst = (nextDrink.alcoholGrams / (bodyMassGrams * r)) * 100.0

        func h(_ dt: TimeInterval) -> Double {
            projectedBAC(
                at: date.addingTimeInterval(dt),
                session: session,
                user: user,
                eaten: eaten
            ) + deltaNextWorst - targetBAC
        }

        // Already safe now?
        if h(0) <= 0 { return date }

        // Exponential search to bracket the root
        var lo: TimeInterval = 0
        var hi: TimeInterval = 15 * 60
        let maxT = maxHours * 3600

        while h(hi) > 0, hi < maxT {
            lo = hi
            hi = min(hi * 2, maxT)
            if hi == lo { break }
        }

        if h(hi) > 0 { return nil }

        // Bisection
        var left = lo
        var right = hi
        while right - left > toleranceSeconds {
            let mid = 0.5 * (left + right)
            if h(mid) > 0 {
                left = mid
            } else {
                right = mid
            }
        }

        return date.addingTimeInterval(right)
    }
}
