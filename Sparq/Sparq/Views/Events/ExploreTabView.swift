import SwiftUI

struct ExploreTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedInterestId: String?
    @State private var selectedEvent: CampusEventCard?

    private var events: [CampusEventCard] { viewModel.eventsData?.events ?? [] }
    private var interests: [Interest] { viewModel.eventsData?.interests ?? [] }

    private var filteredEvents: [CampusEventCard] {
        guard let selectedInterestId else {
            let matched = events.filter { viewModel.isEventForMyInterests($0) }
            return matched.isEmpty ? events : matched
        }
        return events.filter { $0.interestId == selectedInterestId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryChips
                    happeningSoon
                    popularInterests
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(SparqTheme.screenBackground(colorScheme))
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadEvents() }
            .refreshable { await viewModel.loadEvents() }
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button {
                    selectedInterestId = nil
                } label: {
                    Text("For you")
                }
                .sparqChip(selected: selectedInterestId == nil)
                .buttonStyle(.plain)

                ForEach(interests) { interest in
                    Button {
                        selectedInterestId = interest.id
                    } label: {
                        Text(interest.name)
                    }
                    .sparqChip(selected: selectedInterestId == interest.id)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var happeningSoon: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Happening soon")
                .font(.headline.weight(.semibold))

            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "Nothing here yet",
                    systemImage: "calendar",
                    description: Text("Campus events show up as they're added.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredEvents) { event in
                        Button { selectedEvent = event } label: {
                            MockupEventRow(event: event, forYou: viewModel.isEventForMyInterests(event))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var popularInterests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular on campus")
                .font(.headline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(interests) { interest in
                        Button {
                            selectedInterestId = interest.id
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: interest.icon)
                                    .font(.title3)
                                    .foregroundStyle(SparqTheme.accent)
                                    .frame(width: 56, height: 56)
                                    .background(SparqTheme.accentSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Text(interest.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 88)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
