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
    
    var alcoholGrams: Double {
        volumeMl * (abv / 100.0) * 0.789
    }
}

extension Drink {
    static func `default`(for category: Category) -> Drink {
        switch category {
        case .beer:    return .init(category: .beer,    name: "Beer",    volumeMl: 355, abv: 5.0)
        case .wine:    return .init(category: .wine,    name: "Wine",    volumeMl: 150, abv: 13.5)
        case .spirit:  return .init(category: .spirit,  name: "Spirit (1.5 oz)", volumeMl: 44, abv: 40.0)
        case .cocktail:return .init(category: .cocktail,name: "Cocktail",volumeMl: 180, abv: 15.0)
        }
    }
}
