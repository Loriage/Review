import SwiftUI

struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2.weight(.medium))
                .foregroundColor(color)
            
            VStack {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle().fill(defaultBackgroundColor)
        }
        .cornerRadius(12)
    }

    private var defaultBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(.secondarySystemBackground)
        default:
            return .white
        }
    }
}
