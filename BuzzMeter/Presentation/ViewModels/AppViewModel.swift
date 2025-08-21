//
//  AppViewModel.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI
import Foundation
import Combine

final class AppViewModel : ObservableObject {
    @Published var userProfile: UserProfile = .init()
    @Published var session: DrinkSession = .init()
    @Published var plan: BACLevelPlan = .init()
    
    // MARK: - Session
    func addDrinkToSession(_ drink: Drink) {
        let entry = DrinkSession.Entry(drink: drink, startedAt: Date())
        session.entries.append(entry)
    }
    
    // MARK: - Timing helpers (bridge to BACCalculator extension)
    
    /// Earliest time when projected BAC will be <= plan target.
    func etaToReachPlanTarget(from date: Date = Date()) -> Date? {
        BACCalculator.earliestTime(
            toReach: plan.targetBAC,
            from: date,
            session: session,
            user: userProfile,
            eaten: plan.eaten
        )
    }
    
    /// Conservative earliest time you can take `nextDrink` and stay <= plan target.
    func etaSafeForNextDrink(_ nextDrink: Drink, from date: Date = Date()) -> Date? {
        BACCalculator.waitUntilSafeForNextDrink(
            targetBAC: plan.targetBAC,
            nextDrink: nextDrink,
            from: date,
            session: session,
            user: userProfile,
            eaten: plan.eaten
        )
    }
    
    /// Quality‑of‑life utilities for UI
    func isSafeNow(for nextDrink: Drink, at date: Date = Date()) -> Bool {
        guard let t = etaSafeForNextDrink(nextDrink, from: date) else { return false }
        return t <= date
    }
    
    func secondsRemaining(until date: Date?) -> TimeInterval {
        guard let d = date else { return 0 }
        return max(d.timeIntervalSinceNow, 0)
    }
    
    
}
