import SwiftUI

struct InfoPill: View {
    let title: String
    let value: String
    var customBackgroundColor: Color? = nil

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
        .background{
            if let color = customBackgroundColor {
                Rectangle().fill(color)
            } else {
                Rectangle().fill(Material.thin)
            }
        }
        .cornerRadius(12)
    }
}
