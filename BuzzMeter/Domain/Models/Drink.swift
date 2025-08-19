//
//  Drink.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//
import Foundation

struct Drink: Identifiable, Codable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case cocktail, wine, beer, spirit
        var id: String { rawValue }
        
        var defaultABV: Double {
            switch self {
            case .cocktail: return 15.0
            case .wine:     return 13.5
            case .beer:     return 5.0
            case .spirit:   return 40.0
            }
        }
    }

    var id = UUID()
    var category: Category
    var name: String
    var volumeMl: Double
    var abv: Double
    
    // Derived: standardized alcohol units
    var standardDrinks: Double {
        (volumeMl * (abv / 100) * 0.789) / 14.0
    }
}
