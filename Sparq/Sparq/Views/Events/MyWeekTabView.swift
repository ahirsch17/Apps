import SwiftUI

/// Private list of events the student is tracking (“Keep me posted”).
struct MyWeekTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedEvent: CampusEventCard?

    private var tracked: [CampusEventCard] {
        (viewModel.eventsData?.events ?? []).filter(\.isInterested)
    }

    var body: some View {
        NavigationStack {
            Group {
                if tracked.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing tracked yet", systemImage: "bookmark")
                    } description: {
                        Text("Tap Keep me posted on an event to get updates - it’s private and you can drop anytime.")
                    } actions: {
                        Text("Browse For You or Discover to find something.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        Section {
                            Text("Only you see this list. Counts on events stay anonymous.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        }

                        Section("Tracking") {
                            ForEach(tracked) { event in
                                Button { selectedEvent = event } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text("\(event.timeLabel) · \(event.location)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(event.interestedCount) keeping an eye on this")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(SparqTheme.screenBackground(colorScheme))
            .navigationTitle("My Week")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadEvents() }
            .refreshable { await viewModel.loadEvents() }
            .sheet(item: $selectedEvent) { event in
                EventDetailSheet(event: event)
            }
        }
    }
}
