//
//  Drink.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

struct Drink {
    enum Category: String {
        case cocktail, wine, beer
        var id: String { rawValue }
    }
}
