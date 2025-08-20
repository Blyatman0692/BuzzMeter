//
//  CurrentSessionView.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/17/25.
//

import SwiftUI

struct DrinkSessionView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var bac: Double = 0

    private var entries: [DrinkSession.Entry] {
        appVM.session.entries
    }

    private var totalStandardDrinks: Double {
        entries.reduce(0) { $0 + $1.drink.standardDrinks }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Drinks Added",
                    systemImage: "cup.and.saucer",
                    description: Text("Add a drink to start tracking your session.")
                )
            } else {
                List {
                    Section("Drinks in Session") {
                        ForEach(entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.drink.name).font(.headline)

                                    Text("\(entry.drink.category.rawValue.capitalized) • \(Int(entry.drink.volumeMl)) ml • \(entry.drink.abv, specifier: "%.1f")% ABV")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    Text("≈ \(entry.drink.standardDrinks, specifier: "%.2f") standard drinks")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Start: \(entry.startedAt.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)

                                    if let ended = entry.endedAt {
                                        Text("End: \(ended.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            appVM.session.entries.remove(atOffsets: indexSet)
                        }
                    }

                    Section {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text("≈ \(totalStandardDrinks, specifier: "%.2f") standard drinks")
                                .font(.headline)
                        }
                    }
                    
                }
            }
        }
        .navigationTitle("Drink Session")
    }
}


#Preview {
    NavigationView {
        DrinkSessionView()
            .environmentObject(AppViewModel())
    }
}
