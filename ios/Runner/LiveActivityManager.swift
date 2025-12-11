//
//  LiveActivityManager.swift
//  Runner
//
//  Created by phuc on 11/12/25.
//

import Foundation
import ActivityKit

@available(iOS 16.2, *)
class LiveActivityManager {
    private var liveActivity: Activity<LiveActivityMapAttributes>? = nil
    
    
    func startLiveActivity(data: [String: Any]?) {
        let attributes = LiveActivityMapAttributes()
        if let info = data {
            let state = LiveActivityMapAttributes.ContentState(
                remainingDistanceStr: info["remainingDistanceStr"] as? String ?? "",
                progress: info["progress"] as? Int ?? 0,
                minutesToArrive: info["minutesToArrive"] as? Int ?? 0
            )
            Task {
                liveActivity = try? Activity<LiveActivityMapAttributes>.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: .token
                )
            }
        }
        
    }
    
    func updateLiveActivity(data: [String: Any]?) {
        if let info = data {
            let updatedState = LiveActivityMapAttributes.ContentState(
                remainingDistanceStr: info["remainingDistanceStr"] as? String ?? "",
                progress: info["progress"] as? Int ?? 0,
                minutesToArrive: info["minutesToArrive"] as? Int ?? 0
            )
            
            Task {
                await liveActivity?.update(.init(state: updatedState, staleDate: nil))
            }
        }
    }
    
    func endLiveActivity() {
        Task {
            let fifteenMinutesLater = Date().addingTimeInterval(15 * 60)
            await self.liveActivity?.end(dismissalPolicy: .immediate)
        }
    }
}
