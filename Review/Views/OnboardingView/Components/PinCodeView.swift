import SwiftUI

struct PinCodeView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    
    var body: some View {
        VStack {
            if let pinCode = authManager.pin?.code {
                Text(pinCode)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .textSelection(.enabled)
            } else {
                ProgressView()
            }
            
            ProgressView("pin.code.waiting.for.validation")
                .padding(.top)
        }
    }
}
