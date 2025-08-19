//
//  DrinkSesstion.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import Foundation

struct DrinkSession: Identifiable, Codable {
    struct Entry: Identifiable, Codable {
        var id = UUID()
        var drink: Drink
        var startedAt: Date
        var endedAt: Date? = nil
    }

    var id = UUID()
    var entries: [Entry] = []
}
