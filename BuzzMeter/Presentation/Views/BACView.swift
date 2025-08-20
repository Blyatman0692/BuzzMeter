//
//  BACView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/19/25.
//

import SwiftUI

struct BACView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var currentBAC: Double = 0
    

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live BAC readout
            HStack {
                Text("Current BAC:")
                    .font(.headline)
                Text(bacDisplay(currentBAC))
                    .monospacedDigit()
                    .font(.title3.weight(.semibold))
            }

            // Simple gauge to 0.08% cap
            ProgressView(value: min(currentBAC / 0.08, 1.0))
                .progressViewStyle(.linear)
                .tint(.red.opacity(0.8))
        }
        .padding()
        .onAppear(perform: recomputeBAC)
        .onReceive(timer) { _ in recomputeBAC() }
    }

    private func recomputeBAC() {
        currentBAC = BACCalculator.bac(
            at: Date(),
            session: appVM.session,
            user: appVM.userProfile
        )
    }

    private func bacDisplay(_ bac: Double) -> String {
        bac.formatted(.number.precision(.fractionLength(3))) + "%"
    }
}

#Preview {
    NavigationView {
        BACView()
        .environmentObject(AppViewModel())
    }
}
