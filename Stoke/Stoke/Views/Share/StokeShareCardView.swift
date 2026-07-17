import SwiftUI

/// Branded weekly snapshot card for Messages / Photos (image-only share).
struct StokeShareCardView: View {
    let payload: StokeSharePayload

    private static let ink = Color(red: 0.12, green: 0.14, blue: 0.18)
    private static let muted = Color(red: 0.42, green: 0.46, blue: 0.52)
    private static let paper = Color(red: 0.99, green: 0.98, blue: 0.96)
    private static let border = Color(red: 0.82, green: 0.78, blue: 0.72)
    private static let seal = Color(red: 0.18, green: 0.42, blue: 0.38)

    var body: some View {
        ZStack {
            Self.paper
            watermark
            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                hero
                Spacer(minLength: 12)
                statsRow
                Spacer(minLength: 16)
                footer
            }
            .padding(28)
            sealOverlay
        }
        .frame(width: 360, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(certificateFrame)
    }

    private var certificateFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Self.border, lineWidth: 2)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Self.border.opacity(0.55), lineWidth: 1)
                .padding(6)
        }
    }

    private var watermark: some View {
        Text("STOKE")
            .font(.system(size: 88, weight: .black, design: .rounded))
            .foregroundStyle(Self.ink.opacity(0.04))
            .rotationEffect(.degrees(-18))
            .offset(y: 40)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("STOKE")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Self.seal)
            Text("WEEKLY SNAPSHOT")
                .font(.system(size: 10, weight: .semibold, design: .default))
                .tracking(2.2)
                .foregroundStyle(Self.muted)
            Rectangle()
                .fill(Self.border)
                .frame(width: 120, height: 1)
                .padding(.top, 4)
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Self.border.opacity(0.6), lineWidth: 3)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(payload.percent) / 100))
                    .stroke(
                        Self.seal,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                VStack(spacing: 2) {
                    Text("\(payload.percent)%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Self.ink)
                    Text("of weekly goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Self.muted)
                }
            }
            Text(payload.displayName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(title: "Week", value: "\(payload.weekNumber)")
            divider
            statCell(title: "Points", value: "\(payload.earned) / \(payload.target)")
            divider
            statCell(title: "Streak", value: payload.streak > 0 ? "\(payload.streak) wk" : "—")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Self.border.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Self.border.opacity(0.5))
            .frame(width: 1, height: 36)
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Self.muted)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.ink)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text(payload.dateRange)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Self.muted)
            Text("Shared from Stoke")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Self.muted.opacity(0.85))
        }
    }

    private var sealOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Self.paper)
                        .frame(width: 88, height: 88)
                    Circle()
                        .stroke(Self.seal.opacity(0.85), lineWidth: 2.5)
                        .frame(width: 82, height: 82)
                    Circle()
                        .stroke(Self.seal.opacity(0.35), lineWidth: 1)
                        .frame(width: 70, height: 70)
                    VStack(spacing: 2) {
                        Text("STOKE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                        Text("W\(payload.weekNumber)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(issuedStamp)
                            .font(.system(size: 8, weight: .medium))
                        Text("· \(payload.stampMark)")
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Self.muted)
                    }
                    .foregroundStyle(Self.seal)
                }
                .rotationEffect(.degrees(-12))
                .padding(.trailing, 8)
                .padding(.bottom, 4)
            }
        }
        .padding(20)
    }

    private var issuedStamp: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: payload.issuedAt).uppercased()
    }
}

#if DEBUG
#Preview {
    StokeShareCardView(
        payload: StokeSharePayload(
            displayName: "Alex",
            weekNumber: 2,
            earned: 420,
            target: 500,
            percent: 84,
            streak: 1,
            dateRange: "Jun 1 – Jun 7",
            periodEndDay: Date(),
            issuedAt: Date()
        )
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
#endif
