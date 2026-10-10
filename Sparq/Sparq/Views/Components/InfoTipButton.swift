import SwiftUI

struct InfoTipButton: View {
    let title: String
    let message: String
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("\(title) info")
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                ScrollView {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
