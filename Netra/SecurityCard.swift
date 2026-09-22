import SwiftUI

struct SecurityCard: View {
    let icon: String
    let title: String
    let score: Int
    let detail: String
    
    var body: some View {
        HStack(spacing: 16) {
            
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }
}

#Preview {
    SecurityCard(
        icon: "key.fill",
        title: "Credentials",
        score: 82,
        detail: "2 issues"
    )
    .padding()
}
