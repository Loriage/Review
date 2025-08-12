import SwiftUI

struct OnboardingLoginButton: View {
    @EnvironmentObject var authManager: PlexAuthManager
    
    var body: some View {
        VStack {
            if authManager.isLoading {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        await authManager.startLoginProcess()
                    }
                }) {
                    Text("Se connecter avec Plex")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
            }
            
            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
    }
}
