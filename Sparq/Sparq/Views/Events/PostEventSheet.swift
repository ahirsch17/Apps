import SwiftUI

/// Lightweight create flow for club events / student pop-ups (moderation-aware).
struct PostEventSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var kind: PostKind = .popup
    @State private var title = ""
    @State private var location = ""
    @State private var whenText = ""
    @State private var details = ""
    @State private var openSpots = ""
    @State private var rideSeats = ""
    @State private var didSubmit = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(PostKind.allCases) { k in
                            Text(k.label).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(kind.footer)
                }

                Section {
                    TextField("What’s happening?", text: $title)
                    TextField("Where?", text: $location)
                    TextField("When? (e.g. Tonight 7pm)", text: $whenText)
                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Basics")
                }

                Section {
                    TextField("Open spots (optional)", text: $openSpots)
                        .keyboardType(.numberPad)
                    TextField("Ride seats (optional)", text: $rideSeats)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Lower the barrier")
                } footer: {
                    Text("“1 spot left” and “rides included” make joining feel natural - not awkward.")
                }

                if kind == .popup {
                    Section {
                        Label("Pop-ups are reviewed so the feed stays legit.", systemImage: "shield.lefthalf.filled")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submit() }
                        .fontWeight(.semibold)
                        .disabled(!canSubmit)
                }
            }
            .alert("Submitted for review", isPresented: $didSubmit) {
                Button("OK") { dismiss() }
            } message: {
                Text(kind == .popup
                      ? "Your pop-up will show after a quick check so spam doesn’t crowd the feed."
                      : "Thanks - club posts go live once verified.")
            }
        }
    }

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !whenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        // API create + moderation queue comes next; toast keeps the UX honest for demo.
        viewModel.showToast(kind == .popup ? "Pop-up submitted for review" : "Event submitted")
        didSubmit = true
    }
}

private enum PostKind: String, CaseIterable, Identifiable {
    case popup
    case club

    var id: String { rawValue }

    var label: String {
        switch self {
        case .popup: return "Pop-up"
        case .club: return "Club / org"
        }
    }

    var footer: String {
        switch self {
        case .popup:
            return "Pickup games, study groups, lounge hangouts - informal and moderated."
        case .club:
            return "For verified clubs and orgs. Keep it clear and low-pressure."
        }
    }
}
