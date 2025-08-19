//
//  UserProfileView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var appVM: AppViewModel

    // Number formatters
    private let intFormat: IntegerFormatStyle<Int> = .number
    private let doubleFormat: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0...1))

    var body: some View {
        Form {
            Section("Basic") {
                TextField("Name", text: $appVM.userProfile.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Picker("Sex", selection: $appVM.userProfile.sex) {
                    ForEach(UserProfile.Sex.allCases) { sex in
                        Text(sex.rawValue.capitalized).tag(sex)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Stats") {
                // Age (years): numeric TextField
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("0", value: $appVM.userProfile.age, format: intFormat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("Years")
                        .foregroundStyle(.secondary)
                }

                // Weight (kg): numeric TextField
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("0", value: $appVM.userProfile.weightKg, format: doubleFormat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }

                // Height (cm): numeric TextField
                HStack {
                    Text("Height")
                    Spacer()
                    TextField("0", value: $appVM.userProfile.heightCm, format: doubleFormat)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // todo: persistent storage
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                }
            }
        }
        // keep reasonable values
        .onChange(of: appVM.userProfile.age) { oldValue, newValue in
            let clamped = min(max(newValue, 0), 120)
            if newValue != clamped { appVM.userProfile.age = clamped }
        }
        .onChange(of: appVM.userProfile.weightKg) { oldValue, newValue in
            let clamped = min(max(newValue, 0), 500)
            if newValue != clamped { appVM.userProfile.weightKg = clamped }
        }
        .onChange(of: appVM.userProfile.heightCm) { oldValue, newValue in
            let clamped = min(max(newValue, 0), 300)
            if newValue != clamped { appVM.userProfile.heightCm = clamped }
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileView()
    }
    .environmentObject(AppViewModel())
}
