import Foundation
import UserNotifications

/// Gentle reminders only. Never shames; skips early week 1 and hopeless gaps.
@MainActor
final class PaceNudgeService {
    static let shared = PaceNudgeService()

    private enum Keys {
        static let lastOffPaceNudgeDay = "lastOffPaceNudgeDay"
    }

    private init() {}

    func maybeSendOffPaceNudge(
        weekPoints: Double,
        expectedPoints: Double,
        periodTarget: Int,
        weekNumber: Int,
        period: WeekPeriod
    ) async {
        guard periodTarget > 0 else { return }
        guard weekPoints < Double(periodTarget) else { return }
        guard weekPoints > 0 else { return }
        guard weekPoints < expectedPoints - 2 else { return }

        let gap = expectedPoints - weekPoints
        guard gap >= 5, gap <= Double(periodTarget) * 0.45 else { return }

        let dayInPeriod = period.dayIndex(for: Date())
        if weekNumber == 1, dayInPeriod < 3 {
            return
        }

        guard withinNudgeHours() else { return }
        guard !alreadyNudgedToday() else { return }

        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            guard granted == true else { return }
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        let gapInt = max(1, Int(gap.rounded(.up)))
        let content = UNMutableNotificationContent()
        content.title = nudgeTitle(weekNumber: weekNumber)
        content.body = nudgeBody(gap: gapInt, weekNumber: weekNumber)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let id = "stoke.offpace.\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
        markNudgedToday()
    }

    private func nudgeTitle(weekNumber: Int) -> String {
        weekNumber == 1 ? "Stoke check-in" : "Gentle reminder"
    }

    private func nudgeBody(gap: Int, weekNumber: Int) -> String {
        if weekNumber == 1 {
            return "A short walk or easy movement still adds to week one. About \(gap) pts to match today's pace."
        }
        return "You are close. About \(gap) pts to match today's pace. Any movement counts."
    }

    private func withinNudgeHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return (9...20).contains(hour)
    }

    private func alreadyNudgedToday() -> Bool {
        guard let day = UserDefaults.standard.object(forKey: Keys.lastOffPaceNudgeDay) as? Date else {
            return false
        }
        return Calendar.current.isDate(day, inSameDayAs: Date())
    }

    private func markNudgedToday() {
        UserDefaults.standard.set(Date(), forKey: Keys.lastOffPaceNudgeDay)
    }
}
