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
                } footer: {
                    Text("Close friends show up first on your home screen.")
                        .font(BetweenFont.caption())
                }
                
                Section {
                    Toggle(isOn: shareBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share free time overlap")
                                .font(BetweenFont.secondary())
                            Text("Let \(FriendColorPalette.firstName(friend.name)) see when your schedules overlap")
                                .font(BetweenFont.caption())
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Label("Privacy", systemImage: "lock.shield")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your actual schedule stays encrypted and private. \(FriendColorPalette.firstName(friend.name)) will only see if you're both free at the same time.")
                        Text("You can change this for each friend individually.")
                    }
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
        .presentationDetents([.medium, .large])
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
