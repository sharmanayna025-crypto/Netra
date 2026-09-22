//
//  SecurityScoreView.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//

import SwiftUI

struct SecurityScoreView: View {
    
    let score: Int
    
    var scoreStatus: String {
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
        VStack(spacing: 8) {
            
            Text("\(score)")
                .font(.system(size: 64, weight: .bold))
            
            Text("Security Score")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(scoreStatus)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}
