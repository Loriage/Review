import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("permission.denied.title")
                .font(.title2.bold())
            Text("permission.denied.message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
