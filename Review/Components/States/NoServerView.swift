import SwiftUI

struct NoServerView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("no.server.selected.title")
                .font(.title2.bold())
            Text("no.server.selected.message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
