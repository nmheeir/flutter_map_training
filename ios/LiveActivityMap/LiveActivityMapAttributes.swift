//
//  LiveActivityMapAttributes.swift
//  Runner
//
//  Created by phuc on 11/12/25.
//

import Foundation
import ActivityKit

struct LiveActivityMapAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingDistanceStr: String
        var progress: Int
        var minutesToArrive: Int
    }
    
}
