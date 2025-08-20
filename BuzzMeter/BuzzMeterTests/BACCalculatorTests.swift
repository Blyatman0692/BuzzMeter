//
//  BACCalculatorTests.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/20/25.
//

import XCTest
@testable import BuzzMeter

final class BACCalculatorTests: XCTestCase {
    // arrange
    let t0 = Date(timeIntervalSince1970: 1_000_000_000)

    func user(weightKg: Double = 70, sex: UserProfile.Sex = .male) -> UserProfile {
        var u = UserProfile()
        u.weightKg = weightKg
        u.sex = sex
        return u
    }

    func stdDrink(name: String = "Std") -> Drink {
        return Drink(category: .spirit, name: name, volumeMl: 44, abv: 40, notes: nil)
    }

    func session(_ entries: [DrinkSession.Entry]) -> DrinkSession {
        DrinkSession(entries: entries)
    }
    
    
    func test_emptySession_returnsZero() {
        let s = session([])
        let u = user()
        XCTAssertEqual(BACCalculator.bac(at: t0, session: s, user: u), 0.0)
        XCTAssertEqual(BACCalculator.projectedBAC(at: t0, session: s, user: u, eaten: false), 0.0)
    }
    
    func test_naive_oneStandardDrink_exactAtT0() {
        let e = DrinkSession.Entry(drink: stdDrink(), startedAt: t0)
        let s = session([e])
        let u = user(weightKg: 70, sex: .male)
        let bac = BACCalculator.bac(at: t0, session: s, user: u)
        XCTAssertEqual(bac, 0.02941176, accuracy: 1e-6)
    }
    
}
