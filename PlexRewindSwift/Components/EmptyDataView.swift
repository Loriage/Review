import SwiftUI

struct EmptyDataView: View {
    let systemImageName: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImageName)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
