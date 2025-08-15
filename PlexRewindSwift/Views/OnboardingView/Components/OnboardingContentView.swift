import SwiftUI

struct OnboardingContentView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "film.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("onboarding.title")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("onboarding.subtitle")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
