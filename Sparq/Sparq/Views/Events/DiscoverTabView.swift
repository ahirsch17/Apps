import SwiftUI

/// Browseable campus catalog by category / interest.
struct DiscoverTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategory: EventBrowseCategory = .all
    @State private var selectedInterestId: String?
    @State private var selectedEvent: CampusEventCard?
    @State private var searchText = ""

    private var events: [CampusEventCard] { viewModel.eventsData?.events ?? [] }
    private var interests: [Interest] { viewModel.eventsData?.interests ?? [] }

    private var filteredEvents: [CampusEventCard] {
        var list = events
        if let selectedInterestId {
            list = list.filter { $0.interestId == selectedInterestId }
        } else if selectedCategory != .all {
            list = list.filter { $0.category == selectedCategory.rawValue }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.location.localizedCaseInsensitiveContains(searchText)
                    || $0.interestName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryChips
                    if !interests.isEmpty {
                        interestChips
                    }
                    results
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .background(SparqTheme.screenBackground(colorScheme))
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search campus events")
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
                ForEach(EventBrowseCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        selectedInterestId = nil
                    } label: {
                        Text(category.label)
                    }
                    .sparqChip(selected: selectedCategory == category && selectedInterestId == nil)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var interestChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(interests) { interest in
                    Button {
                        selectedInterestId = interest.id
                        selectedCategory = .all
                    } label: {
                        Text(interest.name)
                    }
                    .sparqChip(selected: selectedInterestId == interest.id)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resultsTitle)
                .font(.headline.weight(.semibold))

            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "Nothing in this category yet",
                    systemImage: "magnifyingglass",
                    description: Text("Try another filter - or post a pop-up from the + button.")
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

    private var resultsTitle: String {
        if let selectedInterestId,
           let name = interests.first(where: { $0.id == selectedInterestId })?.name {
            return name
        }
        return selectedCategory.label
    }
}

enum EventBrowseCategory: String, CaseIterable, Identifiable {
    case all
    case official
    case im
    case pickup
    case clubs
    case campus
    case popups
    case local

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .official: return "Official"
        case .im: return "IM leagues"
        case .pickup: return "Pickup"
        case .clubs: return "Clubs"
        case .campus: return "Campus"
        case .popups: return "Pop-ups"
        case .local: return "Local"
        }
    }
}
