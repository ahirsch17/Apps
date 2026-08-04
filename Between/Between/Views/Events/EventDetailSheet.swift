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
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    metaCard

                    socialProofCard

                    if !event.isInterested {
                        Button {
                            Task { await viewModel.markInterested(event) }
                        } label: {
                            Label("I'm interested", systemImage: "hand.thumbsup.fill")
                        }
                        .buttonStyle(BetweenPrimaryButtonStyle())
                    } else {
                        interestedConfirmation
                    }

                    if event.matchingKind != .none {
                        matchingSection
                    }
                }
                .padding(20)
            }
            .background(BetweenTheme.screenBackground(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if event.matchingKind == .newcomer {
                partnerNote = "First time, would love to meet people"
                experience = "Never played pickup here before"
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: event.interestIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BetweenTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(BetweenTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(event.interestName)
                    .font(BetweenFont.captionMedium())
                    .foregroundStyle(BetweenTheme.accent)
            }

            Text(event.title)
                .font(BetweenFont.screenTitle())
                .foregroundStyle(.primary)

            if !event.description.isEmpty {
                Text(event.description)
                    .font(BetweenFont.secondary())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            metaRow(icon: "clock", text: event.timeLabel)
            metaRow(icon: "mappin.and.ellipse", text: event.location)
            if let recurrence = event.recurrenceLabel {
                metaRow(icon: "repeat", text: recurrence)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(BetweenTheme.accentAction)
                .frame(width: 18)
            Text(text)
                .font(BetweenFont.secondary())
                .foregroundStyle(.primary)
        }
    }

    private var interestedConfirmation: some View {
        Label("You're interested", systemImage: "checkmark.circle.fill")
            .font(.body.weight(.semibold))
            .foregroundStyle(BetweenTheme.free)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(BetweenTheme.free.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var socialProofCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 28) {
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
            return "You're not alone. Others on campus want a partner too."
        case .newcomer:
            return "Plenty of Hokies are interested, and some don't know anyone either. Opt in to connect."
        case .none:
            return "Others are going, so show up and work together."
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
            Spacer(minLength: 0)
        }
    }
}
