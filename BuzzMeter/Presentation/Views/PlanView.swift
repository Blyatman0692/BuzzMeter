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

    @State private var buzzLevel: BuzzLevel = .lightheaded
    @State private var category: Drink.Category = .beer

    private let intFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
    private let oneDecimal = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))

    var body: some View {
        Form {
            Section("Desired buzz") {
                Picker("Target Buzz", selection: $buzzLevel) {
                    ForEach(BuzzLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }

            Section("Planned next drink") {
                Picker("Category", selection: $category) {
                    ForEach(Drink.Category.allCases) { c in
                        Text(c.rawValue.capitalized).tag(c)
                    }
                }
            }

            Section {
                Button {
                    let drink = Drink.default(for: category)
                    let plan = BACLevelPlan(targetBAC: buzzLevel.lowerBoundBAC, nextDrink: drink)
                    appVM.plan = plan
                    dismiss()
                } label: {
                    Text("Start Plan")
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
