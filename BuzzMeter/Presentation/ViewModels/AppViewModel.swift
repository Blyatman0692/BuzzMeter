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
    
    func updateUserName(_ name: String) {
        userProfile.name = name
    }
    
    func getUserName() -> String {
        return userProfile.name
    }
}
