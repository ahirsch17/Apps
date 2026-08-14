import SwiftUI

struct ClueInputView: View {
    var disabled: Bool = false
    var boardWords: [String] = []
    var onSubmit: (String, Int) -> Void

    @State private var clueWord = ""
    @State private var numberText = ""
    @State private var alertMessage: String?

    private var canSubmit: Bool {
        !disabled && !clueWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !numberText.isEmpty
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Enter clue word", text: $clueWord)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(disabled)

            TextField("#", text: $numberText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 56)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
                .disabled(disabled)

            Button("Submit") {
                submit()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(canSubmit ? Theme.success : Color.gray.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!canSubmit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .alert("Invalid Clue", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func submit() {
        let parsed = Int(numberText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
        let result = GameLogic.validateClue(word: clueWord, number: parsed, boardWords: boardWords)
        guard result.isValid else {
            alertMessage = result.message
            return
        }
        onSubmit(clueWord.uppercased(), parsed)
        clueWord = ""
        numberText = ""
    }
}
