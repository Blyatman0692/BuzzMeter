//
//  BuzzLevel.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//
import Foundation

final class BACLevelPlan: ObservableObject {
    @Published var targetBAC: Double
    @Published var nextDrink: Drink
    @Published var eaten: Bool
    
    init(targetBAC: Double = 0.06, nextDrink: Drink = Drink.default(for: Drink.Category.beer),eaten: Bool = false) {
        self.targetBAC = targetBAC
        self.eaten = eaten
        self.nextDrink = nextDrink
    }
}
