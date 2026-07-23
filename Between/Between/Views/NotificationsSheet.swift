import SwiftUI

struct NotificationsSheet: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Friend requests") {
                    if viewModel.pendingIncoming.isEmpty {
                        Text("No pending requests")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.pendingIncoming) { request in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.from.name)
                                        .font(.subheadline.weight(.medium))
                                    Text("Wants to connect")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Accept") {
                                    Task { await viewModel.acceptRequest(request) }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }

                if !viewModel.pendingOutgoing.isEmpty {
                    Section("Sent") {
                        ForEach(viewModel.pendingOutgoing, id: \.id) { student in
                            HStack {
                                Text(student.name)
                                Spacer()
                                Text("Pending")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
