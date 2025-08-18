//
//  userProfile.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import Foundation

struct UserProfile: Identifiable, Codable {
    enum Sex: String, Codable, CaseIterable, Identifiable {
        case male, female, other
        var id: String { rawValue }
    }

    var id = UUID()

    // Basic biological traits
    var name: String = ""
    var age: Int = 21
    var weightKg: Double = 70.0
    var sex: Sex = .male
}
