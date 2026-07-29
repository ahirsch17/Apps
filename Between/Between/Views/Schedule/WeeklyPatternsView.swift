import SwiftUI

struct WeeklyPatternsView: View {
    let recurringWindows: [RecurringWindow]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Your weekly patterns",
                subtitle: "Recurring free time"
            )
            
            if recurringWindows.isEmpty {
                emptyState
            } else {
                ForEach(recurringWindows) { window in
                    patternCard(window)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No recurring patterns yet")
                .font(BetweenFont.secondary())
                .foregroundStyle(.secondary)
            Text("Check back after a few days")
                .font(BetweenFont.caption())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private func patternCard(_ window: RecurringWindow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(window.pattern.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(window.pattern.displayName)
                        .font(BetweenFont.captionMedium())
                        .foregroundStyle(BetweenTheme.accent)
                    
                    Text(window.timeLabel)
                        .font(BetweenFont.cardTitle())
                }
                
                Spacer()
                
                Text("\(window.durationMinutes)m")
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BetweenTheme.surfaceMuted(colorScheme))
                    .clipShape(Capsule())
            }
            
            if !window.friendIds.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(window.friendNamesLine)
                        .font(BetweenFont.secondary())
                        .foregroundStyle(.primary)
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: contextIcon(window.contextLabel))
                    .font(.caption2)
                    .foregroundStyle(BetweenTheme.accent)
                
                Text(window.suggestedActivity)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    // TODO: Add to calendar
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                        Text("Add")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BetweenTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, y: 2)
    }
    
    private func contextIcon(_ label: String) -> String {
        switch label {
        case "Lunch": return "fork.knife"
        case "Study block": return "book.fill"
        case "After classes": return "sun.horizon.fill"
        case "Break": return "cup.and.saucer.fill"
        default: return "calendar"
        }
    }
}

#Preview {
    ScrollView {
        WeeklyPatternsView(
            recurringWindows: [
                RecurringWindow(
                    id: "1",
                    pattern: .mwf,
                    startMinutes: 12 * 60,
                    endMinutes: 13 * 60,
                    friendIds: ["1", "2"],
                    friendNames: ["Sarah Chen", "Mike Johnson"],
                    contextLabel: "Lunch"
                ),
                RecurringWindow(
                    id: "2",
                    pattern: .tr,
                    startMinutes: 14 * 60,
                    endMinutes: 16 * 60,
                    friendIds: ["1", "3", "4"],
                    friendNames: ["Sarah Chen", "Rachel Kim", "Alex Smith"],
                    contextLabel: "Study block"
                )
            ]
        )
        .padding(20)
    }
}
