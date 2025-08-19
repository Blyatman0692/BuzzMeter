//
//  AppViewModel.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI
import Foundation
import Combine

final class AppViewModel : ObservableObject {
    @Published var userProfile: UserProfile = .init()
    @Published var session: DrinkSession = .init()
    
    
    // DrinkSession related functions
    func addDrinkToSession(_ drink: Drink) {
       let entry = DrinkSession.Entry(drink: drink, startedAt: Date())
        session.entries.append(entry)
    }
    
    
}
