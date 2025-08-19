//
//  userProfile.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//
//  Domain/Models/UserProfile.swift
import Foundation

struct UserProfile: Identifiable, Codable, Equatable {
    enum Sex: String, Codable, CaseIterable, Identifiable {
        case male, female, other
        var id: String { rawValue }
    }
    
    var id = UUID()

    var name: String
    var age: Int
    var weightKg: Double
    var heightCm: Double
    var sex: Sex

    init(
        id: UUID = UUID(),
        name: String = "Guest",
        age: Int = 0,
        weightKg: Double = 0,
        heightCm: Double = 0,
        sex: Sex = .other
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.sex = sex
    }
}
