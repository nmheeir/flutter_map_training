//
//  DestinationArrivedView.swift
//  Runner
//
//  Created by phuc on 11/12/25.
//

import SwiftUI
import ActivityKit
import WidgetKit

struct DestinationArrivedView: View {
    let context: ActivityViewContext<LiveActivityMapAttributes>

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Đã đến đích!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    Text("Bạn đã hoàn thành chuyến đi.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                
                Image(systemName: "flag.checkered.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
            }
        }
        .padding(20)
    }
}
