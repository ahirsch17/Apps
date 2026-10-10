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
                    LazyVStack(spacing: 10) {
                        ForEach(events) { event in
                            Button { selectedEvent = event } label: {
                                EventExploreCard(event: event, forYou: viewModel.isEventForMyInterests(event))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .background(SparqTheme.screenBackground(colorScheme).ignoresSafeArea())
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
                .foregroundStyle(SparqTheme.accent)
            Text("No events yet")
                .font(SparqFont.cardTitle())
            Text("Campus events for your interests show up here.")
                .font(SparqFont.secondary())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 80)
    }
}
