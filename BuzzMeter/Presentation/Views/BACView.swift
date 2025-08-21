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
    @State private var etaToPlanTarget: Date? = nil
    @State private var planTargetBACDisplay: Double = 0.06
    @State private var showSource: GaugeSource = .projected

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum GaugeSource: String, CaseIterable, Identifiable {
        case naive = "Naive"
        case projected = "Projected"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Naive BAC now:")
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
                Text("Projected BAC now:")
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

            Divider().padding(.vertical, 4)

            // Plan target ETA section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Don't drink until")
                        .font(.headline)
                    if let etaToPlanTarget {
                        Text(etaToPlanTarget, style: .time)
                            .monospacedDigit()
                            .font(.title3.weight(.semibold))
                    } else {
                        Text("> 24h or unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("If you want to stay \(BuzzLevel.fromBAC(appVM.plan.targetBAC))").font(.headline)
                }

                if let etaToPlanTarget {
                    let remaining = max(etaToPlanTarget.timeIntervalSinceNow, 0)
                    Text("Countdown: \(Self.hms(from: remaining))")
                        .monospacedDigit()
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
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

        let eaten = appVM.plan.eaten
        currentProjectedBAC = BACCalculator.projectedBAC(
            at: now,
            session: appVM.session,
            user: appVM.userProfile,
            eaten: eaten
        )

        // Compute ETA to plan target BAC if a plan exists
        let plan = appVM.plan
        planTargetBACDisplay = plan.targetBAC
        etaToPlanTarget = BACCalculator.earliestTime(
            toReach: plan.targetBAC,
            from: now,
            session: appVM.session,
            user: appVM.userProfile,
            eaten: eaten
        )
    }

    private static func hms(from seconds: TimeInterval) -> String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }

}

#Preview {
    NavigationView {
        BACView()
            .environmentObject(AppViewModel())
    }
}
