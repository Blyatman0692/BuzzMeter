//
//  BACLiveActivity.swift
//  BuzzMeter
//
//  Created by Junwen Zheng on 8/19/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BACAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var bac: Double
    }
    // Static attributes (don’t change during activity)
    var userName: String
}
