//
//  PlanView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/20/25.
//

// PlanView.swift
import SwiftUI

struct PlanView: View {
    @EnvironmentObject var appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss

    private var buzzLevelBinding: Binding<BuzzLevel> {
        Binding(
            get: { BuzzLevel.fromBAC(appVM.plan.targetBAC) },
            set: { appVM.plan.targetBAC = $0.lowerBoundBAC }
        )
    }

    private var categoryBinding: Binding<Drink.Category> {
        Binding(
            get: { appVM.plan.nextDrink.category },
            set: { newCategory in
                // When category changes, reset nextDrink to a sensible default for that category
                appVM.plan.nextDrink = Drink.default(for: newCategory)
            }
        )
    }

    private var eatenBinding: Binding<Bool> {
        Binding(
            get: { appVM.plan.eaten },
            set: { appVM.plan.eaten = $0 }
        )
    }

    private let intFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private let oneDecimal = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))
    
    var body: some View {
        Form {
            Section("Desired buzz") {
                Picker("Target Buzz", selection: buzzLevelBinding) {
                    ForEach(BuzzLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }

            Section("Planned next drink") {
                Picker("Category", selection: categoryBinding) {
                    ForEach(Drink.Category.allCases) { c in
                        Text(c.rawValue.capitalized).tag(c)
                    }
                }
            }
            
            Section("Did you eat?") {
                Toggle("Yes", isOn: eatenBinding)
            }

            Section {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    NavigationStack {
        PlanView()
            .environmentObject(AppViewModel())
    }
}
