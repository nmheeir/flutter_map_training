//
//  NavigationTrackingView.swift
//  Runner
//
//  Created by phuc on 11/12/25.
//

import SwiftUI
import ActivityKit
import WidgetKit

// View: Đang di chuyển
struct NavigationTrackingView: View {
    let context: ActivityViewContext<LiveActivityMapAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Đang di chuyển đến đích")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.blue)
                        
                        Text("Cách \(context.state.remainingDistanceStr) • " +
                             (context.state.minutesToArrive <= 0
                              ? "Ít hơn 1 phút"
                              : "\(context.state.minutesToArrive) phút"))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    }
                    
                }
                Spacer()
                
                // Icon Navigation
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
            }
            
            // Thanh tiến trình
            ProgressBarTrack(progress: context.state.progress)
        }
        .padding(20)
    }
}
