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
        let r = widmarkFactor(for: user.sex)

        // Distribution term: A / (weight * r * 10)
        // (The 10 factor folds unit conversions used in many Widmark calculators.)
        let distribution = gramsConsumed / (max(user.weightKg, 1) * r * 10.0)

        // Elimination: beta * hours since first drink
        let hoursSinceStart = max(date.timeIntervalSince(firstDrinkTime) / 3600.0, 0)
        let beta = 0.015  // %BAC per hour (average)
        let eliminated = beta * hoursSinceStart

        // %BAC cannot be negative
        return max(distribution - eliminated, 0)
    }

    /// Project the BAC decline (no new drinks) every `stepMinutes` until 0.
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

    /// Estimated time (hours) until BAC reaches 0 from a given BAC, under average elimination.
    static func timeToZeroHours(from bac: Double, betaPerHour: Double = 0.015) -> Double {
        guard bac > 0 else { return 0 }
        return bac / max(betaPerHour, 1e-9)
    }

    
    private static func widmarkFactor(for sex: UserProfile.Sex) -> Double {
        switch sex {
        case .male:   return 0.68
        case .female: return 0.55
        case .other:  return 0.615
        }
    }
}
