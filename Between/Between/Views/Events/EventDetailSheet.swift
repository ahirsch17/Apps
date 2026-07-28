import SwiftUI

struct EventDetailSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let event: CampusEventCard

    @State private var partnerNote = "Looking for someone to go with"
    @State private var experience = "Open to any skill level"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title)
                            .font(BetweenFont.screenTitle())
                        Text(event.description)
                            .font(BetweenFont.secondary())
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Text("\(event.timeLabel) · \(event.location)")
                            if let recurrence = event.recurrenceLabel {
                                Text("·")
                                Text(recurrence)
                            }
                        }
                        .font(BetweenFont.caption())
                        .foregroundStyle(.secondary)
                    }

                    socialProofCard

                    if !event.isInterested {
                        Button {
                            Task { await viewModel.markInterested(event) }
                        } label: {
                            Text("I'm interested")
                        }
                        .buttonStyle(BetweenPrimaryButtonStyle())
                    }

                    if event.matchingKind != .none {
                        matchingSection
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if event.matchingKind == .newcomer {
                partnerNote = "First time — would love to meet people"
                experience = "Never played pickup here before"
            }
        }
    }

    private var socialProofCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                statBlock(value: "\(event.interestedCount)", label: "interested")
                if event.showsMatching {
                    statBlock(
                        value: "\(event.partnerSeekingCount)",
                        label: event.matchingKind.seekingStatLabel
                    )
                }
            }
            Text(socialProofCopy)
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private var socialProofCopy: String {
        switch event.matchingKind {
        case .partner:
            return "You're not alone — others on campus want a partner too."
        case .newcomer:
            return "Plenty of Hokies are interested. Some don't know anyone either — opt in to connect."
        case .none:
            return "Others are going — show up and work together."
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(BetweenTheme.accent)
            Text(label)
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var matchingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.matchingKind.optInTitle)
                .font(BetweenFont.sectionTitle())

            if !event.canViewPartners {
                Text(event.matchingKind.privacyNote)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)

                TextField(
                    event.matchingKind == .newcomer ? "Quick intro (e.g. first time on campus)" : "Quick intro (e.g. need a setter)",
                    text: $partnerNote
                )
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField(
                    event.matchingKind == .newcomer ? "Your comfort level" : "Your experience",
                    text: $experience
                )
                .padding(12)
                .background(BetweenTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await viewModel.markLookingForPartner(event, note: partnerNote, experience: experience) }
                } label: {
                    Label(event.matchingKind.optInButton, systemImage: "lock.open")
                }
                .buttonStyle(BetweenPrimaryButtonStyle())
            } else {
                Text(event.matchingKind.seekersSectionTitle)
                    .font(BetweenFont.captionMedium())
                    .foregroundStyle(BetweenTheme.free)

                ForEach(event.partnerProfiles) { profile in
                    partnerRow(profile)
                }
            }
        }
        .surfaceCard()
    }

    private func partnerRow(_ profile: PartnerSeekingProfile) -> some View {
        HStack(alignment: .top, spacing: 12) {
            FriendAvatarView(name: profile.displayName, friendId: profile.studentId, size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(profile.displayName) · \(profile.year)")
                    .font(BetweenFont.secondary().weight(.medium))
                Text(profile.lookingNote)
                    .font(BetweenFont.caption())
                Text(profile.experienceNote)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
