import SwiftUI

struct FunFactsSection: View {
    @ObservedObject var viewModel: TopStatsViewModel

    private func timeOfDayIcon(for timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "sunset.fill"
        case .night: "moon.stars.fill"
        }
    }

    var body: some View {
        Section(header: Text("En bref").font(.headline)) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    if let totalPlays = viewModel.funFactTotalPlays, totalPlays > 0 {
                        StatPill(title: "Lectures", value: "\(totalPlays)", icon: "play.tv.fill", color: .blue)
                    }
                    if let time = viewModel.funFactFormattedWatchTime {
                        StatPill(title: "Temps total", value: time, icon: "hourglass", color: .purple)
                    }
                    if let day = viewModel.funFactMostActiveDay {
                        StatPill(title: "Jour favori", value: day, icon: "calendar", color: .red)
                    }
                }
                HStack(spacing: 10) {
                    if let user = viewModel.funFactTopUser {
                        StatPill(title: "Top Profil", value: user, icon: "person.fill", color: .orange)
                    }
                    if let timeOfDay = viewModel.funFactBusiestTimeOfDay {
                        StatPill(title: "Moment phare", value: timeOfDay.rawValue, icon: timeOfDayIcon(for: timeOfDay), color: .indigo)
                    }
                    if let users = viewModel.funFactActiveUsers, users > 0 {
                        StatPill(title: "Profils actifs", value: "\(users)", icon: "person.3.fill", color: .cyan)
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}
