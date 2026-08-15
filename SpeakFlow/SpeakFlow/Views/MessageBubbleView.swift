import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let language: Language

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            if message.role == .tutor {
                HStack(spacing: 6) {
                    Text(language.flag)
                    Text(language.tutorName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Text(message.text)
                .padding(12)
                .background(message.role == .user ? SFTheme.accent : Color(.secondarySystemBackground))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if !message.corrections.isEmpty {
                VStack(spacing: 8) {
                    ForEach(message.corrections) { CorrectionCardView(correction: $0) }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct CorrectionCardView: View {
    let correction: Correction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(correction.type.label, systemImage: correction.type.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            HStack(spacing: 4) {
                Text(correction.original).strikethrough().foregroundStyle(.secondary)
                Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                Text(correction.corrected).fontWeight(.semibold)
            }
            .font(.subheadline)
            Text(correction.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(0.2), lineWidth: 1)
        )
    }

    private var accent: Color {
        switch correction.type {
        case .englishLeak: return .orange
        case .pronunciation: return .purple
        case .tense: return .blue
        case .grammar: return .red
        case .vocabulary: return .green
        }
    }
}
