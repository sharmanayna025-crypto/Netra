//
//  ScoreRing.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import SwiftUI

struct ScoreRing: View {
    
    let score: Int
    
    private var progress: Double {
        Double(score) / 100.0
    }
    
    private var status: String {
        switch score {
        case 90...100:
            return "Excellent"
        case 75..<90:
            return "Good"
        case 50..<75:
            return "Needs Attention"
        default:
            return "At Risk"
        }
    }
    
    var body: some View {
        ZStack {
            
            Circle()
                .stroke(
                    .quaternary,
                    lineWidth: 14
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    NetraTheme.accent,
                    style: StrokeStyle(
                        lineWidth: 14,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold))
                
                Text(status.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
        .animation(.easeInOut, value: score)
    }
}

#Preview {
    ScoreRing(score: 85)
}