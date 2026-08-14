import SwiftUI

struct RulesView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundView()

        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            rulesSection(title: "The Bluff Protocol") {
              Text("Intelligence agencies use \"The Bluff Protocol\" to test operatives. Agents are dropped into unfamiliar locations and must either identify their location or remain undetected until extraction. Residents must expose the Spy before the mission succeeds.")
            }

            rulesSection(title: "Setup") {
              Text("3–8 players. One player is secretly the Spy; everyone else is a Resident. Residents see the same secret location. The Spy only sees that they are the Spy and must figure out the location.")
            }

            rulesSection(title: "Spy objective") {
              Text("Hold / submit a location guess. Correct → Spy wins. Wrong → Residents win. The Spy can also win by surviving until time runs out.")
            }

            rulesSection(title: "Resident objective") {
              Text("Ask careful questions about the location, then vote to detain the Spy. Majority correct detain → Residents win. Tie or wrong detainee → Spy wins.")
            }

            rulesSection(title: "How to play") {
              Text("1. Location reveal — Residents see the place; Spy sees only their role.\n\n2. Question phase — A random starter asks first; play continues clockwise. Ask any player about the location.\n\n3. Voting — When everyone is ready, vote for who you think is the Spy. Majority decides; ties favor the Spy.\n\n4. Spy guess — The Spy gets one location guess per game. Use it carefully.")
            }

            rulesSection(title: "Tips") {
              Text("Residents: Ask location-specific questions and watch for vague answers.\n\nSpy: Ask broad questions, give plausible vague answers, and listen for clues.")
            }

            Text("Typical round: 5–10 minutes")
              .font(.footnote.weight(.semibold))
              .foregroundStyle(.white.opacity(0.7))
              .frame(maxWidth: .infinity)
              .padding(.top, 4)
          }
          .padding(16)
          .padding(.bottom, 28)
        }
      }
      .navigationTitle("Rules")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
            .foregroundStyle(.white)
        }
      }
      .toolbarBackground(.hidden, for: .navigationBar)
    }
  }

  @ViewBuilder
  private func rulesSection(title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(.title3, design: .serif).weight(.bold))
        .foregroundStyle(.white)

      content()
        .font(.body)
        .foregroundStyle(.white.opacity(0.9))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.black.opacity(0.55))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.white.opacity(0.12), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}
