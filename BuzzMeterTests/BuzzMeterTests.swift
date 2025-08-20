//
//  BuzzMeterTests.swift
//  BuzzMeterTests
//
//  Created by Junwen Zheng on 8/20/25.
//

import Foundation
import Testing
@testable import BuzzMeter

// MARK: - Helpers

private let t0 = Date(timeIntervalSince1970: 1_000_000_000)

private func mkUser(weightKg: Double = 70, sex: UserProfile.Sex = .male) -> UserProfile {
    var u = UserProfile()
    u.weightKg = weightKg
    u.sex = sex
    return u
}

/// 1 U.S. "standard drink" ≈ 14 g ethanol.
private func stdDrink(name: String = "Std") -> Drink {
    // 14g ethanol ~ 17.75 mL; at 40% ABV it's ~44 mL spirit.
    Drink(category: .spirit, name: name, volumeMl: 44, abv: 40)
}

private func mkSession(_ entries: [DrinkSession.Entry]) -> DrinkSession {
    DrinkSession(entries: entries)
}

private func approx(_ a: Double, _ b: Double, tol: Double = 1e-6) -> Bool {
    abs(a - b) <= tol
}


struct BuzzMeterTests {
    
    // 1) Empty session → 0
    @Test
    func emptySession_isZero() {
        let s = mkSession([])
        let u = mkUser()
        #expect(BACCalculator.bac(at: t0, session: s, user: u) == 0)
        #expect(BACCalculator.projectedBAC(at: t0, session: s, user: u, eaten: false) == 0)
    }
    
    // 2) Naive exact value for one standard drink at t0 (no elimination)
    // For 70 kg, male, A=14g:
    @Test
    func naive_oneStandardDrink_exactAtT0() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser(weightKg: 70, sex: .male)
        let bac = BACCalculator.bac(at: t0, session: s, user: u)
        
        
        let grams = e.drink.alcoholGrams
        let r = u.alcoholDistributionRatio
        let expected = (grams / (u.weightKg * 1000 * r)) * 100.0
        
        #expect(abs(bac - expected) < 1e-9)
    }
    
    // 3) Naive elimination after 2 hours (floored at 0)
    @Test
    func naive_afterTwoHours_nonNegative() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        let bac = BACCalculator.bac(at: t0.addingTimeInterval(2*3600), session: s, user: u)
        #expect(bac >= 0)
    }
    
    // 4) Projected: before lag → zero even with a drink (fasted lag ~12 min per model)
    @Test
    func projected_beforeLag_isZero() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        let bac = BACCalculator.projectedBAC(
            at: t0.addingTimeInterval(5*60), // 5 minutes
            session: s,
            user: u,
            eaten: false
        )
        #expect(approx(bac, 0.0, tol: 1e-9))
    }
    
    // 5) Projected < Naive early after drinking (not fully absorbed yet)
    @Test
    func projected_isBelowNaive_early() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        
        let t = t0.addingTimeInterval(25*60) // ~just after fasted lag
        let naive = BACCalculator.bac(at: t, session: s, user: u)
        let projected = BACCalculator.projectedBAC(at: t, session: s, user: u, eaten: false)
        
        #expect(projected > 0)
        #expect(projected < naive)
    }
    
    // 6) “eaten” slows absorption at the same timestamp
    @Test
    func projected_eatenLowerThanFasted_early() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        let t = t0.addingTimeInterval(35*60)
        
        let fasted = BACCalculator.projectedBAC(at: t, session: s, user: u, eaten: false)
        let fed    = BACCalculator.projectedBAC(at: t, session: s, user: u, eaten: true)
        
        #expect(fed < fasted)
    }
    
    // 7) Projected ≈ Naive much later (after absorption completes; allow tolerance)
    @Test
    func projected_convergesTowardNaive_afterLongTime() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        
        let t = t0.addingTimeInterval(3*3600) // long after
        let naive = BACCalculator.bac(at: t, session: s, user: u)
        let projected = BACCalculator.projectedBAC(at: t, session: s, user: u, eaten: false)
        
        #expect(approx(projected, naive, tol: 0.003)) // within 0.003 %BAC
    }
    
    // 8) Multiple drinks spaced out → monotonic rise during absorption window
    @Test
    func projected_monotonicRise_withStaggeredDrinks() {
        let d1 = DrinkSession.Entry(drink: stdDrink(name: "1"), startedAt: t0)
        let d2 = DrinkSession.Entry(drink: stdDrink(name: "2"), startedAt: t0.addingTimeInterval(20*60))
        let s = mkSession([d1, d2])
        let u = mkUser()
        
        let t1 = t0.addingTimeInterval(30*60)
        let t2 = t0.addingTimeInterval(50*60)
        let b1 = BACCalculator.projectedBAC(at: t1, session: s, user: u, eaten: false)
        let b2 = BACCalculator.projectedBAC(at: t2, session: s, user: u, eaten: false)
        
        #expect(b2 > b1)
    }
    
    // 9) Order of entries shouldn’t matter
    @Test
    func entryOrder_doesNotAffectProjected() {
        let d1 = DrinkSession.Entry(drink: stdDrink(name: "1"), startedAt: t0)
        let d2 = DrinkSession.Entry(drink: stdDrink(name: "2"), startedAt: t0.addingTimeInterval(10*60))
        let s1 = mkSession([d1, d2])
        let s2 = mkSession([d2, d1])
        let u = mkUser()
        let t = t0.addingTimeInterval(70*60)
        
        let b1 = BACCalculator.projectedBAC(at: t, session: s1, user: u, eaten: false)
        let b2 = BACCalculator.projectedBAC(at: t, session: s2, user: u, eaten: false)
        #expect(approx(b1, b2, tol: 1e-9))
    }
    
    // 10) Clamp non-negative after long time
    @Test
    func bac_isNeverNegative() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        let u = mkUser()
        let t = t0.addingTimeInterval(10*3600)
        
        #expect(BACCalculator.bac(at: t, session: s, user: u) >= 0)
        #expect(BACCalculator.projectedBAC(at: t, session: s, user: u, eaten: false) >= 0)
    }
    
    // 11) Distribution sensitivity: heavier or larger r → lower BAC
    @Test
    func distributionSensitivity_weightAndSex() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = mkSession([e])
        
        let male70 = mkUser(weightKg: 70, sex: .male)
        let female70 = mkUser(weightKg: 70, sex: .female)
        let male90 = mkUser(weightKg: 90, sex: .male)
        
        let bMale70 = BACCalculator.bac(at: t0, session: s, user: male70)
        let bFemale70 = BACCalculator.bac(at: t0, session: s, user: female70)
        let bMale90 = BACCalculator.bac(at: t0, session: s, user: male90)
        
        #expect(bFemale70 > bMale70) // smaller r → higher BAC
        #expect(bMale90   < bMale70) // heavier → lower BAC
    }
    
}
