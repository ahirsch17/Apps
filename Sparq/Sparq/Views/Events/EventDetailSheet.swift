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
                            Label("Keep me posted", systemImage: "bell")
                        }
                        .buttonStyle(SparqPrimaryButtonStyle())

                        Text("Private by default - only a count shows. Get updates if turnout changes, a spot opens, or details shift. Drop anytime.")
                            .font(SparqFont.caption())
                            .foregroundStyle(.secondary)
                    } else {
                        interestedConfirmation
                    }

                    if event.matchingKind != .none {
                        if event.isInterested {
                            matchingSection
                        } else {
                            Text("After you keep this on your radar, you can optionally opt in to find a partner.")
                                .font(SparqFont.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .background(SparqTheme.screenBackground(colorScheme).ignoresSafeArea())
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
            EventCoverImage(imageName: event.coverImageName, height: 180)

            HStack(spacing: 8) {
                Image(systemName: event.interestIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparqTheme.accent)
                    .frame(width: 28, height: 28)
                    .background(SparqTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(event.interestName)
                    .font(SparqFont.captionMedium())
                    .foregroundStyle(SparqTheme.accent)
            }

            Text(event.title)
                .font(SparqFont.screenTitle())
                .foregroundStyle(.primary)

            if !event.description.isEmpty {
                Text(event.description)
                    .font(SparqFont.secondary())
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
                .foregroundStyle(SparqTheme.accentAction)
                .frame(width: 18)
            Text(text)
                .font(SparqFont.secondary())
                .foregroundStyle(.primary)
        }
    }

    private var interestedConfirmation: some View {
        VStack(spacing: 6) {
            Label("Keeping you posted", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SparqTheme.free)
            Text("You’re on the private list. No one sees your name unless you opt in later.")
                .font(SparqFont.caption())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(SparqTheme.free.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: SparqTheme.buttonRadius, style: .continuous))
    }

    private var socialProofCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 28) {
                statBlock(value: "\(event.interestedCount)", label: "keeping an eye")
                if event.showsMatching {
                    statBlock(
                        value: "\(event.partnerSeekingCount)",
                        label: event.matchingKind.seekingStatLabel
                    )
                }
            }
            Text(socialProofCopy)
                .font(SparqFont.caption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }

    private var socialProofCopy: String {
        switch event.matchingKind {
        case .partner:
            return "Counts only - names stay private. Opt in if you want a partner."
        case .newcomer:
            return "Others are tracking this too. Opt in only if you want to meet people going."
        case .none:
            return "People are keeping an eye on this. Tap Keep me posted for updates - zero commitment."
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(SparqTheme.accent)
            Text(label)
                .font(SparqFont.caption())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var matchingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.matchingKind.optInTitle)
                .font(SparqFont.sectionTitle())

            if !event.canViewPartners {
                Text(event.matchingKind.privacyNote)
                    .font(SparqFont.caption())
                    .foregroundStyle(.secondary)

                TextField(
                    event.matchingKind == .newcomer ? "Quick intro (e.g. first time on campus)" : "Quick intro (e.g. need a setter)",
                    text: $partnerNote
                )
                .padding(12)
                .background(SparqTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField(
                    event.matchingKind == .newcomer ? "Your comfort level" : "Your experience",
                    text: $experience
                )
                .padding(12)
                .background(SparqTheme.surfaceMuted(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await viewModel.markLookingForPartner(event, note: partnerNote, experience: experience) }
                } label: {
                    Label(event.matchingKind.optInButton, systemImage: "lock.open")
                }
                .buttonStyle(SparqPrimaryButtonStyle())
            } else {
                Text(event.matchingKind.seekersSectionTitle)
                    .font(SparqFont.captionMedium())
                    .foregroundStyle(SparqTheme.free)

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
                    .font(SparqFont.secondary().weight(.medium))
                Text(profile.lookingNote)
                    .font(SparqFont.caption())
                Text(profile.experienceNote)
                    .font(SparqFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
