//
//  BuzzLevel.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/20/25.
//
import Foundation

public enum BuzzLevel: String, CaseIterable, Identifiable, Codable {
    case sober
    case lightheaded
    case buzzed
    case legallyIntoxicated
    case drunk
    case veryDrunk
    case dazedAndConfused
    case stupor
    case coma

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sober: return "Sober"
        case .lightheaded: return "Lightheaded"
        case .buzzed: return "Buzzed"
        case .legallyIntoxicated: return "Legally Intoxicated"
        case .drunk: return "Drunk"
        case .veryDrunk: return "Very Drunk"
        case .dazedAndConfused: return "Dazed and Confused"
        case .stupor: return "Stupor"
        case .coma: return "Coma"
        }
    }

    public var lowerBoundBAC: Double {
        switch self {
        case .sober: return 0.0
        case .lightheaded: return 0.02
        case .buzzed: return 0.05
        case .legallyIntoxicated: return 0.08
        case .drunk: return 0.11
        case .veryDrunk: return 0.16
        case .dazedAndConfused: return 0.20
        case .stupor: return 0.25
        case .coma: return 0.31
        }
    }

    public var upperBoundBAC: Double {
        switch self {
        case .sober: return 0.02
        case .lightheaded: return 0.05
        case .buzzed: return 0.08
        case .legallyIntoxicated: return 0.11
        case .drunk: return 0.16
        case .veryDrunk: return 0.20
        case .dazedAndConfused: return 0.25
        case .stupor: return 0.31
        case .coma: return .infinity
        }
    }

    // MARK: - Conversions

    public var representativeBAC: Double {
        if upperBoundBAC.isInfinite { return lowerBoundBAC }
        return (lowerBoundBAC + upperBoundBAC) / 2.0
    }
 
    public static func fromBAC(_ bac: Double) -> BuzzLevel {
        switch bac {
        case ..<0.02: return .sober
        case 0.02..<0.05: return .lightheaded
        case 0.05..<0.08: return .buzzed
        case 0.08..<0.11: return .legallyIntoxicated
        case 0.11..<0.16: return .drunk
        case 0.16..<0.20: return .veryDrunk
        case 0.20..<0.25: return .dazedAndConfused
        case 0.25..<0.31: return .stupor
        default: return .coma
        }
    }
}
