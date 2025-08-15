import SwiftUI

struct InfoPill: View {
    let title: LocalizedStringKey
    let value: String
    var customBackgroundColor: Color? = nil
    var customBackgroundMaterial: Material? = nil

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.headline.weight(.semibold))
                }

                Spacer()
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background {
            if let material = customBackgroundMaterial {
                Rectangle().fill(material)
            } else if let color = customBackgroundColor {
                Rectangle().fill(color)
            } else {
                Rectangle().fill(defaultBackgroundColor)
            }
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
