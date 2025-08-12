import SwiftUI

struct OnboardingContentView: View {
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
        }
    }
}
