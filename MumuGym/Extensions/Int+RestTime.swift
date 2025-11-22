import Foundation

extension Int {
    var formattedRestTime: String {
        if self == 0 {
            return "SS" // SuperSet
        } else if self < 60 {
            return "\(self)s"
        } else {
            let minutes = self / 60
            let seconds = self % 60
            if seconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(seconds)s"
            }
        }
    }
}