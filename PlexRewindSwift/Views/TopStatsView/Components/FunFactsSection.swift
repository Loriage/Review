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
        Section(header: Text("fun.facts.section.title").font(.headline)) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    if let totalPlays = viewModel.funFactTotalPlays, totalPlays > 0 {
                        StatPill(title: "fun.facts.total.plays", value: "\(totalPlays)", icon: "play.tv.fill", color: .blue)
                    }
                    if let time = viewModel.funFactFormattedWatchTime {
                        StatPill(title: "fun.facts.total.time", value: time, icon: "hourglass", color: .purple)
                    }
                    if let day = viewModel.funFactMostActiveDay {
                        StatPill(title: "fun.facts.favorite.day", value: "\(day)", icon: "calendar", color: .red)
                    }
                }
                HStack(spacing: 10) {
                    if let user = viewModel.funFactTopUser {
                        StatPill(title: "fun.facts.top.user", value: "\(user)", icon: "person.fill", color: .orange)
                    }
                    if let timeOfDay = viewModel.funFactBusiestTimeOfDay {
                        StatPill(title: "fun.facts.busiest.time", value: timeOfDay.displayName, icon: timeOfDayIcon(for: timeOfDay), color: .indigo)
                    }
                    if let users = viewModel.funFactActiveUsers, users > 0 {
                        StatPill(title: "fun.facts.active.users", value: "\(users)", icon: "person.3.fill", color: .cyan)
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}
