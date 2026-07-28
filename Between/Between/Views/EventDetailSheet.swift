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
                        Text("\(event.timeLabel) · \(event.location)")
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

                    partnerSection
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
    }

    private var socialProofCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                statBlock(value: "\(event.interestedCount)", label: "interested")
                if event.partnerSeekingCount > 0 {
                    statBlock(value: "\(event.partnerSeekingCount)", label: "need a partner")
                }
            }
            Text("You're not alone — others on campus want to go too.")
                .font(BetweenFont.caption())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
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
    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Looking for a partner?")
                .font(BetweenFont.sectionTitle())

            if !event.canViewPartners {
                Text("Partner profiles are private until you opt in too. Your info stays visible only to other seekers.")
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)

                TextField("Quick intro (e.g. need a setter)", text: $partnerNote)
                    .padding(12)
                    .background(BetweenTheme.surfaceMuted(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Your experience", text: $experience)
                    .padding(12)
                    .background(BetweenTheme.surfaceMuted(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await viewModel.markLookingForPartner(event, note: partnerNote, experience: experience) }
                } label: {
                    Label("I'm looking for a partner", systemImage: "lock.open")
                }
                .buttonStyle(BetweenPrimaryButtonStyle())
            } else {
                Text("Others looking for a partner")
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

