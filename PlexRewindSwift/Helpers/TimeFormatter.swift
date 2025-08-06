import Foundation

struct TimeFormatter {
    static func formatSeconds(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "0m"
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    static func formatRemainingSeconds(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "Terminé"
        }
        return "\(formatSeconds(seconds)) restantes"
    }
}
