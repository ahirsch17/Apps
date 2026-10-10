import SwiftUI

/// Loads event cover art from Assets using the name stored on `CampusEvent.coverImageName`.
struct EventCoverImage: View {
    let imageName: String?
    var height: CGFloat = 148
    var cornerRadius: CGFloat = SparqTheme.cornerRadius

    var body: some View {
        Group {
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    SparqTheme.accentSoft
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(SparqTheme.accent.opacity(0.5))
                }
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Shared card chrome - flat white, hairline border, sharp corners.
struct SparqCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(SparqTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous)
                    .strokeBorder(SparqTheme.divider(colorScheme), lineWidth: 0.5)
            )
    }
}

struct SparqSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}

/// Horizontal event row: photo left, details right (Explore mockup).
struct MockupEventRow: View {
    let event: CampusEventCard
    let forYou: Bool

    var body: some View {
        HStack(spacing: 0) {
            EventCoverImage(imageName: event.coverImageName, height: 108, cornerRadius: 0)
                .frame(width: 108)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(event.timeLabel) · \(event.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if event.interestedCount > 0 {
                    Text("\(event.interestedCount) keeping an eye")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if event.isInterested {
                    Text("On your week")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(SparqTheme.accent)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "bookmark")
                .font(.body)
                .foregroundStyle(SparqTheme.accent)
                .padding(.trailing, 12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

/// Photo-first event card (vertical layout).
struct EventExploreCard: View {
    let event: CampusEventCard
    let forYou: Bool
    var imageHeight: CGFloat = 132

    var body: some View {
        SparqCard {
            VStack(alignment: .leading, spacing: 0) {
                EventCoverImage(imageName: event.coverImageName, height: imageHeight, cornerRadius: 0)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(event.interestName)
                            .font(SparqFont.captionMedium())
                            .foregroundStyle(SparqTheme.accent)
                        if forYou {
                            Text("For you")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(SparqTheme.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(SparqTheme.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        Spacer(minLength: 0)
                    }

                    Text(event.title)
                        .font(SparqFont.cardTitle())
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(event.timeLabel) · \(event.location)")
                        .font(SparqFont.caption())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if event.interestedCount > 0 {
                        Text("\(event.interestedCount) keeping an eye")
                            .font(SparqFont.caption())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
            }
        }
    }
}
