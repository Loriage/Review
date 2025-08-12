import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack {
            OnboardingContentView()
            OnboardingLoginButton()
        }
        .padding(30)
    }
}
