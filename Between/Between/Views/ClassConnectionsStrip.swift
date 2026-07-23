import SwiftUI

struct ClassConnectionsStrip: View {
    let connections: [ClassConnection]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Classes")
                    .font(.headline)
                Spacer()
                InfoTipButton(
                    title: "Class matches",
                    message: "See which friends share a course — same section or a different section this semester. Only visible for friends you've added."
                )
            }

            if connections.isEmpty {
                Text("Add friends to see class overlap.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(connections.prefix(10)) { connection in
                            chip(connection)
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private func chip(_ connection: ClassConnection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(connection.courseCode)
                .font(.caption.weight(.bold))
            Text(connection.friendName.components(separatedBy: " ").first ?? connection.friendName)
                .font(.caption2)
            Text(connection.kind.shortLabel)
                .font(.caption2)
                .foregroundStyle(connection.kind.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(connection.kind.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("\(connection.friendName), \(connection.courseCode), \(connection.kind.label)")
    }
}

#Preview {
    ClassConnectionsStrip(connections: [])
        .padding()
}
