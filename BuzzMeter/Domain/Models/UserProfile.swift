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
        case male, female
        var id: String { rawValue }
    }
    
    var id = UUID()

    var name: String
    var age: Int
    var weightKg: Double
    var heightCm: Double
    var sex: Sex
    
    /// BAC related parameters
    var totalBodyWater: Double {
        switch sex {
        case .male:
            return 2.447 - 0.09156 * Double(age) + 0.1074 * heightCm + 0.3362 * weightKg
        
        case .female:
            return -2.097 + 0.1069 * heightCm + 0.2466 * weightKg
        }
    }
    
    var alcoholDistributionRatio: Double {
        return totalBodyWater / weightKg
    }

    init(
        id: UUID = UUID(),
        name: String = "Guest",
        age: Int = 0,
        weightKg: Double = 0,
        heightCm: Double = 0,
        sex: Sex = .male
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.sex = sex
    }
}
