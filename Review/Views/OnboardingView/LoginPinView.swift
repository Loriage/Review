import SwiftUI

struct LoginPinView: View {
    var body: some View {
        VStack(spacing: 30) {
            PinInstructionsView()
            PinCodeView()
        }
        .padding(30)
    }
}
