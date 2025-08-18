//
//  DrinkInputView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct DrinkInputView: View {
//    @EnvironmentObject private var vm: AppViewModel

    var body: some View {
        Form {
            TextField("Volume (ml)",text: .constant("10"))
            TextField("ABV (%)",text: .constant("5"))
        }
        .navigationTitle("Current Drink")
    }
}
