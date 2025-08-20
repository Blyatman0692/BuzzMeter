//
//  BuzzLevel.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//
import Foundation

struct BACLevelPlan: Identifiable, Codable {
    var id = UUID()
    var targetBAC: Double
    var nextDrink: Drink
}
