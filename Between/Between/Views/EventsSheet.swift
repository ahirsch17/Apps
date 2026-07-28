import SwiftUI

struct EventsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEvent: CampusEventCard?

    private var events: [CampusEventCard] { viewModel.eventsData?.events ?? [] }

    var body: some View {
        NavigationStack {
            List {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No events yet",
                        systemImage: "calendar",
                        description: Text("Campus events for your interests show up here")
                    )
                } else {
                    ForEach(events) { event in
                        Button { selectedEvent = event } label: {
                            eventRow(event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
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

    private func eventRow(_ event: CampusEventCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: event.interestIcon)
                    .foregroundStyle(BetweenTheme.accent)
                Text(event.interestName)
                    .font(BetweenFont.captionMedium())
                    .foregroundStyle(BetweenTheme.accent)
                Spacer()
                if viewModel.isEventForMyInterests(event) {
                    Text("For you")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BetweenTheme.accentSoft)
                        .clipShape(Capsule())
                }
            }
            Text(event.title)
                .font(BetweenFont.secondary().weight(.semibold))
                .foregroundStyle(.primary)
            Text("\(event.timeLabel) · \(event.location)")
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label("\(event.interestedCount) interested", systemImage: "hand.thumbsup")
                if event.partnerSeekingCount > 0 {
                    Label("\(event.partnerSeekingCount) need a partner", systemImage: "person.2")
                }
            }
            .font(BetweenFont.caption())
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
