//
//  DrinkInputView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct DrinkInputView: View {
    @EnvironmentObject var appVM: AppViewModel
    
    @State private var category: Drink.Category = .cocktail
    @State private var name: String = ""
    @State private var volumeMl: Double = 0
    @State private var abv: Double = Drink.Category.cocktail.defaultABV
    
    var body: some View {
        Form {
            Picker("Category", selection: $category) {
                ForEach(Drink.Category.allCases) { c in
                    Text(c.rawValue.capitalized).tag(c)
                }
            }
            .onChange(of: category) {
                abv = category.defaultABV
            }
            TextField("Name", text: $name)
            HStack {
                Text("Volume (ml)")
                Spacer()
                TextField("0", value: $volumeMl, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("ABV (%)")
                Spacer()
                TextField("0", value: $abv, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            Button("Start") {
                let drink = Drink(
                    category: category,
                    name: name.isEmpty ? category.rawValue.capitalized : name,
                    volumeMl: volumeMl,
                    abv: abv
                )
                appVM.addDrinkToSession(drink)
            }
            .disabled(volumeMl <= 0 || abv <= 0 || abv > 100)
        }
        .navigationTitle("Add Drink")
    }
}

#Preview {
    NavigationView {
        DrinkInputView()
            .environmentObject(AppViewModel())
    }
}
