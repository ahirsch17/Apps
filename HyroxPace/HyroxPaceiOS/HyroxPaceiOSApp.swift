import SwiftUI

@main
struct HyroxPaceiOSApp: App {
    var body: some Scene {
        WindowGroup {
            CompanionView()
        }
    }
}

struct CompanionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "applewatch")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.yellow)

            Text("HyroxPace")
                .font(.largeTitle.bold())

            Text("The race runs on your Apple Watch.")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Open the Watch app on this iPhone", systemImage: "1.circle.fill")
                Label("Scroll to Available Apps", systemImage: "2.circle.fill")
                Label("Tap Install next to HyroxPace", systemImage: "3.circle.fill")
            }
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
    }
}
