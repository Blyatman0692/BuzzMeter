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
    }

    var id = UUID()
    var category: Category
    var name: String
    var volumeMl: Double
    var abv: Double
    var notes: String?

    // Derived: standardized alcohol units
    var standardDrinks: Double {
        (volumeMl * (abv / 100) * 0.789) / 14.0
    }
}
