//
//  LiveActivityMapLiveActivity.swift
//  LiveActivityMap
//
//  Created by phuc on 11/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI



struct LiveActivityMapLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityMapAttributes.self) { context in
            // Giao diện hiển thị trên màn hình khóa / banner thông s
            if context.state.progress < 100 {
                NavigationTrackingView(context: context)
                    .activityBackgroundTint(Color.black.opacity(0.8))
            } else {
                DestinationArrivedView(context: context)
                    .activityBackgroundTint(Color.black.opacity(0.8))
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (Khi nhấn giữ vào Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Còn lại")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(context.state.remainingDistanceStr)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Dự kiến")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(context.state.minutesToArrive <= 0
                             ? "Ít hơn 1 phút"
                             : "\(context.state.minutesToArrive) p")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding(.trailing, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Thanh tiến trình
                    VStack {
                        ProgressBarTrack(progress: context.state.progress)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                
            } compactLeading: {
                // UI thu nhỏ bên trái
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .padding(.leading, 4)
            } compactTrailing: {
                // UI thu nhỏ bên phải (khoảng cách)
                Text(context.state.remainingDistanceStr)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            } minimal: {
                // UI nhỏ nhất (khi có nhiều app dùng đảo)
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

extension Text {
    
    func semiBold20() -> some View {
        self.fontWeight(.semibold).font(.system(size: 20)).foregroundColor(.white)
    }
    
    func regular16() -> some View {
        self.fontWeight(.regular).font(.system(size: 16)).foregroundColor(.gray.opacity(0.8))
    }
}
