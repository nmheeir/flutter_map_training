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
    
    init(progress: Int) {
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            // Hiển thị số %
            Text("\(progress)%")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack(alignment: .leading) {
                
                // Thanh progress — Tăng độ dày
                ProgressView(value: Double(progress), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .background(Color.gray.opacity(0.4))
                    .frame(height: 40)                     // ⬆ tăng chiều cao
                    .cornerRadius(10)
                    .overlay(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    barWidth = geometry.size.width
                                }
                                .onChange(of: geometry.size.width) { width in
                                    barWidth = width
                                }
                        }
                    )
                
                // Icon xe
                Image(systemName: "car.side")
                    .resizable()
                    .renderingMode(.original)
                    .scaleEffect(x: -1, y: 1)               // lật ngang xe
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .offset(x: max(0, (CGFloat(progress) / 100) * barWidth - 18))
            }
        }
        .padding(.horizontal)
    }
}

