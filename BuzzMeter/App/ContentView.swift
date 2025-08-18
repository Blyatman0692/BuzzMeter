//
//  ContentView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink("User Profile", destination: UserProfileView())
                NavigationLink("Input Current Drink", destination: DrinkInputView())
                NavigationLink("Current Session", destination: CurrentSessionView())
            }
            .navigationTitle("BuzzMeter")
        }
    }
}

#Preview {
    ContentView()
}
