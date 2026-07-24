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
                        Label("Close friend", systemImage: "star.fill")
                    }
                    Toggle(isOn: shareBinding) {
                        Label("Share my free time", systemImage: "eye")
                    }
                } footer: {
                    Text("Close friends show up first on your home screen.")
                        .font(BetweenFont.caption())
                }
            }
            .navigationTitle(FriendColorPalette.firstName(friend.name))
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
