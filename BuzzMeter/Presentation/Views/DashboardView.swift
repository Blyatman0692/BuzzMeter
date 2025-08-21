//
//  BACView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/19/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appVM: AppViewModel
    
    @State private var currentNaiveBAC: Double = 0
    @State private var currentProjectedBAC: Double = 0
    @State private var etaToPlanTarget: Date? = nil
    @State private var planTargetBACDisplay: Double = 0
    
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                SpeedometerCard(
                    title: "Naïve BAC",
                    value: currentNaiveBAC,
                    cap: BuzzLevel.coma.lowerBoundBAC,
                    description: BACCalculator.description(for: currentNaiveBAC)
                )
                
                SpeedometerCard(
                    title: "Projected BAC",
                    value: currentProjectedBAC,
                    cap: BuzzLevel.coma.lowerBoundBAC,
                    description: BACCalculator.description(for: currentProjectedBAC)
                )
            }
            .padding(.top, 6)
            
            Divider().padding(.horizontal)
            
            // row with countdown
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Don't drink until")
                        .font(.headline)
                    
                    if let eta = etaToPlanTarget {
                        Text(eta, style: .time)
                            .monospacedDigit()
                            .font(.title3.weight(.semibold))
                    } else {
                        Text("> 24h or unknown")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Target buzz label on the right
                    let target = appVM.plan.targetBAC
                    Text("to stay \(BuzzLevel.fromBAC(target))")
                        .font(.headline)
                }
                
                // Live countdown without manual timer wiring
                if let eta = etaToPlanTarget {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let remaining = max(eta.timeIntervalSinceNow, 0)
                        Text("Countdown: \(Self.hms(from: remaining))")
                            .monospacedDigit()
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
        }
        .padding()
        .onAppear(perform: recompute)
        .onReceive(timer) { _ in
            recompute()
        }
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

private struct SpeedometerCard: View {
    let title: String
    let value: Double
    let cap: Double
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Gauge(value: min(value, cap), in: 0...cap) {
                VStack(spacing: 0) {
                    Text(value.formatted(.number.precision(.fractionLength(3))) + "%")
                        .font(.system(size: 6, weight: .semibold))
                        .monospacedDigit()
                    
                    Text(BuzzLevel.fromBAC(value).displayName)
                        .font(.system(size: 6, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .gaugeStyle(.accessoryCircular)
            .tint(tint(for: value))
            .scaleEffect(2)
            .frame(height: 100)
            
            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
    
    private func tint(for v: Double) -> Color {
        switch v {
        case ..<0.02:     return .green
        case 0.02..<0.05: return .mint
        case 0.05..<0.08: return .yellow
        case 0.08..<0.11: return .orange
        case 0.11..<0.16: return .red
        case 0.16..<0.20: return .purple
        case 0.20..<0.25: return .pink
        case 0.25..<0.31: return .black
        default:          return .gray.opacity(0.6)
        }
    }
}

#Preview {
    NavigationView {
        DashboardView()
            .environmentObject(AppViewModel())
    }
}
