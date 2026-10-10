import SwiftUI

/// Personalized campus feed - primary home for the engagement hub.
struct ForYouTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedEvent: CampusEventCard?

    private var events: [CampusEventCard] { viewModel.eventsData?.events ?? [] }

    private var forYouEvents: [CampusEventCard] {
        let matched = events.filter { viewModel.isEventForMyInterests($0) }
        return matched.isEmpty ? events : matched
    }

    private var trending: [CampusEventCard] {
        Array(events.sorted { $0.interestedCount > $1.interestedCount }.prefix(5))
    }

    private var happeningSoon: [CampusEventCard] {
        Array(forYouEvents.prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    if !trending.isEmpty {
                        trendingSection
                    }
                    happeningSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(SparqTheme.screenBackground(colorScheme))
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadEvents() }
            .refreshable { await viewModel.loadEvents() }
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What’s happening around campus")
                .font(.title3.weight(.semibold))
            Text("IM team fills, recurring pickup spots, clubs, and campus hangouts - private tracking, no class schedules.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending now")
                .font(.headline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trending) { event in
                        Button { selectedEvent = event } label: {
                            EventExploreCard(
                                event: event,
                                forYou: viewModel.isEventForMyInterests(event),
                                imageHeight: 110
                            )
                            .frame(width: 240)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var happeningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Happening soon")
                .font(.headline.weight(.semibold))

            if happeningSoon.isEmpty {
                ContentUnavailableView(
                    "Nothing here yet",
                    systemImage: "sparkles",
                    description: Text("Campus events show up as clubs and VT post them.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(happeningSoon) { event in
                        Button { selectedEvent = event } label: {
                            MockupEventRow(event: event, forYou: viewModel.isEventForMyInterests(event))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
