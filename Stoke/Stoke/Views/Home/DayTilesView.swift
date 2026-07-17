import SwiftUI

struct DayTilesView: View {
    let dates: [Date]
    let pointsByDay: [Date: Double]
    private let calendar = Calendar.current

    private let labels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                let dayStart = calendar.startOfDay(for: date)
                let points = pointsByDay[dayStart] ?? 0
                let filled = points >= 0.5
                let isToday = calendar.isDateInToday(date)

                VStack(spacing: 6) {
                    Text(label(for: date))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(StokeTheme.inkMuted)

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(filled ? StokeTheme.terracotta : Color.white.opacity(0.7))
                            .frame(height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isToday ? StokeTheme.terracottaDeep : Color.clear, lineWidth: 2)
                            )

                        if filled {
                            Text("\(Int(points.rounded()))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func label(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        return labels[weekday - 1]
    }
}
