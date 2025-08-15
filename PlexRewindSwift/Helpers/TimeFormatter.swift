import Foundation

struct TimeFormatter {
    static func formatSeconds(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        if seconds == 0 {
            return "common.finished"
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static func formatFullTime(_ seconds: Int) -> String {
        if seconds <= 0 {
            return "0m"
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secondsLeft = seconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(secondsLeft)s"
        } else {
            return "\(minutes)m \(secondsLeft)s"
        }
    }

    static func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMdd", options: 0, locale: Locale.current)
        return formatter.string(from: date)
    }
}
