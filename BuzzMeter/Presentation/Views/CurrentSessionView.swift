//
//  CurrentSessionView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct CurrentSessionView: View {
    // later this should bind to your AppViewModel
    @State private var volumeMl: Double = 330
    @State private var abvPercent: Double = 5.0

    var body: some View {
        Form {
            Section(header: Text("Drink Details")) {
                HStack {
                    Text("Volume (ml)")
                    Spacer()
                    TextField("ml", value: $volumeMl, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("ABV (%)")
                    Spacer()
                    TextField("%", value: $abvPercent, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section {
                Button("Save Dummy Drink") {
                    print("Saved drink: \(volumeMl)ml @ \(abvPercent)% ABV")
                }
            }
        }
        .navigationTitle("Current Drink")
    }
}

#Preview {
    NavigationView {
        DrinkInputView()
    }
}
