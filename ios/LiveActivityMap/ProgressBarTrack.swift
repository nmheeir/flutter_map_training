//
//  ProgressBarTrack.swift
//  Runner
//
//  Created by phuc on 11/12/25.
//

import SwiftUI

struct ProgressBarTrack: View {
    var progress: Int = 0
     @State private var barWidth: CGFloat = 0
     init(progress: Int ) {
         self.progress = progress
     }
     var body: some View {
         VStack {
             ZStack(alignment: .leading) {
                 ProgressView(value: Double(self.progress), total: 100)
                     .progressViewStyle(LinearProgressViewStyle(tint: .white)).background(Color.gray.opacity(0.4)).frame(height: 28)
                                         .cornerRadius(6)
                     .overlay(
                         GeometryReader { geometry in
                             Color.clear.onAppear {
                                 self.barWidth = geometry.size.width
                             }
                         }
                     )

                 ZStack {
                     Image("car")
                         .resizable()
                         .frame(width: 32, height: 42)
                         .scaledToFit()
                 }
                 .offset(x: CGFloat(Double(self.progress) / 100) * barWidth - 32)
             }
             .padding(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
             
            
         }
     }
}

