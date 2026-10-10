import SwiftUI

struct ColorPanel: View {
    @Bindable var session: EditSession

    var body: some View {
        if session.mode == .drawMask {
            MaskTools(session: session)
        } else if session.edit.shifts.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    shiftChips
                    if let shift = session.activeShift {
                        ShiftEditor(session: session, shift: shift)
                    }
                }
                .padding()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("Tap any color in your photo to change just that color: teeth, eyes, sky, water, grass. Similar shades move together, so it still looks real.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                session.startPicking()
            } label: {
                Label(session.mode == .pickColor ? "Tap the photo…" : "Pick a color", systemImage: "eyedropper")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.black)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    private var shiftChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(session.edit.shifts) { shift in
                    Button {
                        session.activeShiftID = shift.id
                        session.mode = .view
                    } label: {
                        HStack(spacing: 4) {
                            Swatch(color: shift.target, size: 20)
                            Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
                            Swatch(color: shift.params.result, size: 20)
                            if !shift.strokes.isEmpty {
                                Image(systemName: "scribble").font(.caption2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(shift.id == session.activeShiftID ? Theme.accent.opacity(0.25) : Theme.card)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    session.startPicking()
                } label: {
                    Image(systemName: session.mode == .pickColor ? "eyedropper.full" : "plus")
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(session.mode == .pickColor ? Theme.accent.opacity(0.3) : Theme.card))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ShiftEditor: View {
    @Bindable var session: EditSession
    let shift: ColorShift

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Swatch(color: shift.target, size: 34)
                Image(systemName: "arrow.right").foregroundStyle(.secondary)
                ColorPicker("Exact color", selection: session.resultColorBinding, supportsOpacity: false)
                    .labelsHidden()
                Spacer()
                Button {
                    session.startPicking(replacingActive: true)
                } label: {
                    Image(systemName: "eyedropper")
                }
                .accessibilityLabel("Pick a different color")
                Button {
                    session.showSelection.toggle()
                } label: {
                    Image(systemName: session.showSelection ? "circle.lefthalf.filled" : "circle.dashed")
                }
                .accessibilityLabel("Show what's selected")
                Button(role: .destructive) {
                    session.deleteActiveShift()
                } label: {
                    Image(systemName: "trash")
                }
            }
            .font(.system(size: 17))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShiftPreset.suggestions(for: shift.target)) { preset in
                        Button { session.applyPreset(preset) } label: {
                            HStack(spacing: 6) {
                                Swatch(color: preset.preview(from: shift.target), size: 18)
                                Text(preset.name).font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(isApplied(preset) ? Theme.accent.opacity(0.3) : Theme.card))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            LabeledSlider(
                title: "Range of similar colors",
                value: session.shiftBinding(\.range),
                range: 0...1,
                neutral: 0.4,
                format: { $0 < 0.25 ? "Narrow" : $0 < 0.6 ? "Medium" : "Wide" }
            )
            LabeledSlider(title: "Lightness", value: session.shiftBinding(\.lightness))
            LabeledSlider(title: "Intensity", value: session.shiftBinding(\.chroma))
            LabeledSlider(
                title: "Hue",
                value: session.shiftBinding(\.hueShift),
                range: -60...60,
                format: { String(format: "%+.0f°", $0) }
            )

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Where").font(.subheadline)
                    Text(shift.strokes.isEmpty ? "Whole photo" : "Only the area you drew")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(shift.strokes.isEmpty ? "Draw area" : "Edit area") {
                    session.maskTool = shift.strokes.isEmpty ? .lasso : .brush
                    session.mode = .drawMask
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func isApplied(_ preset: ShiftPreset) -> Bool {
        shift.lightness == preset.lightness && shift.chroma == preset.chroma && shift.hueShift == preset.hueShift
    }
}

private struct MaskTools: View {
    @Bindable var session: EditSession

    var body: some View {
        VStack(spacing: 14) {
            Picker("Tool", selection: $session.maskTool) {
                ForEach(EditSession.MaskTool.allCases) { tool in
                    Label(tool.rawValue, systemImage: tool.symbol).tag(tool)
                }
            }
            .pickerStyle(.segmented)

            if session.maskTool == .brush || session.maskTool == .erase {
                HStack {
                    Image(systemName: "circle.fill").font(.system(size: 6))
                    Slider(value: $session.brushSize, in: 8...120)
                    Image(systemName: "circle.fill").font(.system(size: 16))
                }
                .foregroundStyle(.secondary)
            }

            LabeledSlider(
                title: "Edge softness",
                value: session.shiftBinding(\.feather),
                range: 0...0.08,
                neutral: 0.025,
                format: { "\(Int(($0 / 0.08 * 100).rounded()))%" }
            )

            HStack {
                Button { session.undoStroke() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                    .disabled(session.activeShift?.strokes.isEmpty ?? true)
                Spacer()
                Button("Clear", role: .destructive) { session.clearMask() }
                    .disabled(session.activeShift?.strokes.isEmpty ?? true)
                Spacer()
                Button("Done") { session.mode = .view }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.black)
            }
            .font(.subheadline)

            Spacer(minLength: 0)
        }
        .padding()
    }
}
