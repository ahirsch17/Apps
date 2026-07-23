import SwiftUI

struct FriendSettingsSheet: View {
    let friend: FriendCard
    @ObservedObject var preferences: FriendPreferencesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: starBinding) {
                        Label("Starred friend", systemImage: "star.fill")
                    }
                    Toggle(isOn: shareBinding) {
                        Label("Can see when I'm free", systemImage: "eye")
                    }
                } footer: {
                    Text("Starred friends appear on your Today timeline. Turn off visibility for anyone you don't want seeing your free blocks.")
                        .font(.caption)
                }
            }
            .navigationTitle(friend.name.components(separatedBy: " ").first ?? friend.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var starBinding: Binding<Bool> {
        Binding(
            get: { preferences.isStarred(friend.id) },
            set: { preferences.setStarred(friend.id, starred: $0) }
        )
    }

    private var shareBinding: Binding<Bool> {
        Binding(
            get: { preferences.sharesFreeTime(with: friend.id) },
            set: { preferences.setSharesFreeTime($0, with: friend.id) }
        )
    }
}
