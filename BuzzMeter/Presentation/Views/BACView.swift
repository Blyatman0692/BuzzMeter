//
//  BACView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/19/25.
//

import SwiftUI

struct BACView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var currentNaiveBAC: Double = 0
    @State private var currentProjectedBAC: Double = 0
    @State private var showSource: GaugeSource = .projected
    @State private var ateRecently: Bool = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum GaugeSource: String, CaseIterable, Identifiable {
        case naive = "Naive"
        case projected = "Projected"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Naive BAC:")
                    .font(.headline)
                Text(currentNaiveBAC.formatted(.number.precision(.fractionLength(3))) + "%")
                    .monospacedDigit()
                    .font(.title3.weight(.semibold))
                Spacer()
            }

            Text(BACCalculator.description(for: currentNaiveBAC))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().padding(.vertical, 4)

            HStack {
                Text("Projected BAC:")
                    .font(.headline)
                Text(currentProjectedBAC.formatted(.number.precision(.fractionLength(3))) + "%")
                    .monospacedDigit()
                    .font(.title3.weight(.semibold))
                Spacer()
            }

            Text(BACCalculator.description(for: currentProjectedBAC))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Ate recently?", isOn: $ateRecently)
        }
        .padding()
        .onAppear(perform: recompute)
        .onReceive(timer) { _ in recompute() }
    }

    private func recompute() {
        let now = Date()
        currentNaiveBAC = BACCalculator.bac(
            at: now,
            session: appVM.session,
            user: appVM.userProfile
        )

        currentProjectedBAC = BACCalculator.projectedBAC(
            at: now,
            session: appVM.session,
            user: appVM.userProfile,
            eaten: ateRecently
        )
    }

}

#Preview {
    NavigationView {
        BACView()
        .environmentObject(AppViewModel())
    }
}
