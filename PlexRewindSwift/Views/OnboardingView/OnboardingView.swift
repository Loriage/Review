import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "film.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Bienvenue sur Plex Rewind")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Revivez votre année de visionnage avec des statistiques personnalisées sur vos films et séries préférés.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
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
        .padding(30)
    }
}
