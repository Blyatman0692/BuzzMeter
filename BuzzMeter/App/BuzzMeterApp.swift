//
//  BuzzMeterApp.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

@main
struct BuzzMeterApp: App {
    @StateObject private var appVM = AppViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environmentObject(appVM)
    }
}
