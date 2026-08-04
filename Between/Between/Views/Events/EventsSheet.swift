import SwiftUI

struct EventsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: CampusEventCard?

    private var events: [CampusEventCard] { viewModel.eventsData?.events ?? [] }

    var body: some View {
        NavigationStack {
            ScrollView {
                if events.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(events) { event in
                            Button { selectedEvent = event } label: {
                                EventCard(event: event, forYou: viewModel.isEventForMyInterests(event))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .background(BetweenTheme.screenBackground(colorScheme).ignoresSafeArea())
            .navigationTitle("Campus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
            }
            .task { await viewModel.loadEvents() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 34))
                .foregroundStyle(BetweenTheme.accent)
            Text("No events yet")
                .font(BetweenFont.cardTitle())
            Text("Campus events for your interests show up here.")
                .font(BetweenFont.secondary())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 80)
    }
}

private struct EventCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let event: CampusEventCard
    let forYou: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 16)
            footer
        }
        .background(BetweenTheme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: BetweenTheme.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 8, y: 2)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                interestBadge
                Text(event.interestName)
                    .font(BetweenFont.captionMedium())
                    .foregroundStyle(BetweenTheme.accent)
                Spacer(minLength: 8)
                if forYou {
                    Text("For you")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(BetweenTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(BetweenTheme.accentSoft)
                        .clipShape(Capsule())
                }
            }

            Text(event.title)
                .font(BetweenFont.cardTitle())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Label {
                Text("\(event.timeLabel) · \(event.location)")
            } icon: {
                Image(systemName: "clock")
            }
            .font(BetweenFont.caption())
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var interestBadge: some View {
        Image(systemName: event.interestIcon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(BetweenTheme.accent)
            .frame(width: 32, height: 32)
            .background(BetweenTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: 14) {
            metric(icon: "hand.thumbsup.fill", text: "\(event.interestedCount) interested")
            if event.showsMatching {
                metric(
                    icon: event.matchingKind == .newcomer ? "person.wave.2.fill" : "person.2.fill",
                    text: "\(event.partnerSeekingCount) \(event.matchingKind.seekingShortLabel)"
                )
            }
            Spacer(minLength: 0)
            if let recurrence = event.recurrenceLabel {
                Label(recurrence, systemImage: "repeat")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .font(BetweenFont.caption())
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func metric(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(BetweenTheme.accentAction)
            Text(text)
        }
    }
}
