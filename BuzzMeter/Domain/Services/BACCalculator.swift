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
    
    
    /// Projected BAC at `date`, summing per-drink absorption and per-drink elimination.
    /// - Assumptions:
    ///   - First‑order absorption after a lag (tLag).
    ///   - Constant elimination rate `β` applied per drink from the end of its lag.
    ///   - Drinks that begin in the future (relative to `date`) contribute nothing yet.
    static func projectedBAC(
        at date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool
    ) -> Double {
        // Fasted vs. fed absorption parameters (population‑level approximations)
        let tLagSeconds: TimeInterval = eaten ? 25 * 60 : 12 * 60      // 25 min vs 12 min
        let kaPerHour: Double = eaten ? 0.5 : 1.0                      // ~0.5/h vs ~1.0/h
        let kaPerSecond = kaPerHour / 3600.0
        
        // Widmark distribution
        let r = user.alcoholDistributionRatio
        let bodyMassGrams = max(user.weightKg, 1) * 1000.0
        
        // Elimination rate
        let beta: Double = 0.015
        
        // Helper: convert grams in body to %BAC
        func gramsToPercentBAC(_ grams: Double) -> Double {
            (grams / (bodyMassGrams * r)) * 100.0
        }
        
        // Sum per‑drink BAC contributions
        var totalBAC = 0.0
        
        for entry in session.entries {
            // Ignore drinks that haven't started yet
            guard entry.startedAt <= date else { continue }
            
            let A0 = entry.drink.alcoholGrams
            
            // Time since drink start
            let tSinceStart = date.timeIntervalSince(entry.startedAt)
            
            // If we're still within lag for this drink, nothing absorbed yet
            if tSinceStart <= tLagSeconds {
                continue
            }
            
            // Absorption time (post-lag)
            let dtAbsorb = tSinceStart - tLagSeconds
            
            // First‑order absorption: fraction absorbed by now
            let fractionAbsorbed = 1.0 - exp(-kaPerSecond * dtAbsorb)
            let absorbedGrams = min(A0 * fractionAbsorbed, A0)
            
            // Gross BAC contribution from this drink
            let bacGross_i = gramsToPercentBAC(absorbedGrams)
            
            // Per‑drink elimination clock starts when lag ends for this drink
            let hoursSinceAbsorptionStart = dtAbsorb / 3600.0
            let eliminated_i = beta * max(hoursSinceAbsorptionStart, 0)
            
            // Net, clamp at zero (a single drink’s contribution can be fully eliminated)
            let bacNet_i = max(bacGross_i - eliminated_i, 0.0)
            
            totalBAC += bacNet_i
        }
        
        // Never negative overall
        return max(totalBAC, 0.0)
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
    /// If `requireNonIncreasing` is true, we won't return `date` if BAC is about to rise above target soon.
    static func earliestTime(
        toReach targetBAC: Double,
        from date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool,
        maxHours: Double = 24,
        toleranceSeconds: TimeInterval = 30,
        requireNonIncreasing: Bool = true,
        riseLookaheadHours: Double = 2,
        sampleStepSeconds: TimeInterval = 300  // 5 min
    ) -> Date? {

        func bac(at dt: TimeInterval) -> Double {
            projectedBAC(at: date.addingTimeInterval(dt), session: session, user: user, eaten: eaten)
        }
        func g(_ dt: TimeInterval) -> Double { bac(at: dt) - targetBAC }

        // If currently at/below target, optionally verify it won't pop above soon.
        if g(0) <= 0 {
            if !requireNonIncreasing { return date }

            let horizon = min(riseLookaheadHours * 3600, maxHours * 3600)
            var t: TimeInterval = 0
            var willExceed = false
            while t <= horizon {
                if g(t) > 0 { willExceed = true; break }
                t += sampleStepSeconds
            }
            if !willExceed { return date }

            // Start search from the first time we saw it above target.
            // Ensure lo has g(lo) > 0, then bracket and bisect as usual.
            var lo = max(0, t - sampleStepSeconds)
            var hi: TimeInterval = min(lo + 15 * 60, maxHours * 3600)
            while g(hi) > 0, hi < maxHours * 3600 {
                lo = hi
                hi = min(hi * 2, maxHours * 3600)
                if hi == lo { break }
            }
            if g(hi) > 0 { return nil } // never comes back down within horizon

            var left = lo, right = hi
            while right - left > toleranceSeconds {
                let mid = 0.5 * (left + right)
                if g(mid) > 0 { left = mid } else { right = mid }
            }
            return date.addingTimeInterval(right)
        }

        // Normal case: we're above target now → bracket, then bisect.
        var lo: TimeInterval = 0
        var hi: TimeInterval = 15 * 60
        let maxT = maxHours * 3600

        while g(hi) > 0, hi < maxT {
            lo = hi
            hi = min(hi * 2, maxT)
            if hi == lo { break }
        }
        if g(hi) > 0 { return nil }

        var left = lo, right = hi
        while right - left > toleranceSeconds {
            let mid = 0.5 * (left + right)
            if g(mid) > 0 { left = mid } else { right = mid }
        }
        return date.addingTimeInterval(right)
    }

    /// Conservative: earliest time you can take `nextDrink` and remain <= targetBAC
    /// assuming instant absorption of the next drink.
    /// If `requireNonIncreasing` is true, we won't return `date` if (current + worst‑case jump) will exceed target soon.
    static func waitUntilSafeForNextDrink(
        targetBAC: Double,
        nextDrink: Drink,
        from date: Date,
        session: DrinkSession,
        user: UserProfile,
        eaten: Bool,
        maxHours: Double = 24,
        toleranceSeconds: TimeInterval = 30,
        requireNonIncreasing: Bool = true,
        riseLookaheadHours: Double = 2,
        sampleStepSeconds: TimeInterval = 300  // 5 min
    ) -> Date? {

        // Worst-case instant jump at take time
        let r = user.alcoholDistributionRatio
        let bodyMassGrams = max(user.weightKg, 1) * 1000.0
        let deltaNextWorst = (nextDrink.alcoholGrams / (bodyMassGrams * r)) * 100.0

        func bac(at dt: TimeInterval) -> Double {
            projectedBAC(at: date.addingTimeInterval(dt), session: session, user: user, eaten: eaten)
        }
        func h(_ dt: TimeInterval) -> Double { bac(at: dt) + deltaNextWorst - targetBAC }

        if h(0) <= 0 {
            if !requireNonIncreasing { return date }

            let horizon = min(riseLookaheadHours * 3600, maxHours * 3600)
            var t: TimeInterval = 0
            var willExceed = false
            while t <= horizon {
                if h(t) > 0 { willExceed = true; break }
                t += sampleStepSeconds
            }
            if !willExceed { return date }

            // Start search from first exceed time.
            var lo = max(0, t - sampleStepSeconds)
            var hi: TimeInterval = min(lo + 15 * 60, maxHours * 3600)
            while h(hi) > 0, hi < maxHours * 3600 {
                lo = hi
                hi = min(hi * 2, maxHours * 3600)
                if hi == lo { break }
            }
            if h(hi) > 0 { return nil }

            var left = lo, right = hi
            while right - left > toleranceSeconds {
                let mid = 0.5 * (left + right)
                if h(mid) > 0 { left = mid } else { right = mid }
            }
            return date.addingTimeInterval(right)
        }

        // Normal case: not safe yet → bracket, then bisect.
        var lo: TimeInterval = 0
        var hi: TimeInterval = 15 * 60
        let maxT = maxHours * 3600

        while h(hi) > 0, hi < maxT {
            lo = hi
            hi = min(hi * 2, maxT)
            if hi == lo { break }
        }
        if h(hi) > 0 { return nil }

        var left = lo, right = hi
        while right - left > toleranceSeconds {
            let mid = 0.5 * (left + right)
            if h(mid) > 0 { left = mid } else { right = mid }
        }
        return date.addingTimeInterval(right)
    }
}
