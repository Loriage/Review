import SwiftUI

struct InfoPill: View {
    let title: String
    let value: String
    
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
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}
