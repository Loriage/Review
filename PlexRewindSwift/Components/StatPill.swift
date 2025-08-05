import SwiftUI

struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2.weight(.medium))
                .foregroundColor(color)
            
            VStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
