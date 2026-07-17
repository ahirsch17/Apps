import SwiftUI

struct RulesView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Rules")
            .font(.title.bold())

          Text("This is the native SwiftUI version of BluffLocation. Hook up the same gameplay rules you had in React Native here.")
            .foregroundStyle(.secondary)

          VStack(alignment: .leading, spacing: 8) {
            Text("Gameplay (high-level)")
              .font(.headline)
            Text("• Create or join a room\n• Start the game\n• Receive your role (Spy or Location)\n• Discuss and vote\n• Spy can guess the location")
          }
          .padding(.top, 6)
        }
        .padding(16)
      }
      .navigationTitle("Rules")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

