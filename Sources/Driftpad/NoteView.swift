import SwiftUI
import AppKit

struct NoteView: View {
    @ObservedObject var model: NoteModel
    var onClose: () -> Void

    @AppStorage(AppSettings.tintHexKey) private var tintHex = AppSettings.defaultTintHex
    @AppStorage(AppSettings.tintStrengthKey) private var tintStrength = AppSettings.defaultTintStrength

    @FocusState private var isFocused: Bool
    private let font = Font.system(size: 13)
    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            textArea
        }
        .frame(width: AppSettings.noteWidth)   // fixed width, so the height can be measured
        .noteGlass(in: shape, tint: Color(hex: tintHex), strength: tintStrength)
        .onAppear { isFocused = true }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            Text(statusText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()

            Button {
                model.isPinned.toggle()
            } label: {
                Image(systemName: model.isPinned ? "pin.fill" : "pin")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(model.isPinned ? Color(hex: tintHex) : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(model.isPinned ? "Unpin note" : "Pin note")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete note")
        }
        .padding(.horizontal, 12)
        .padding(.top, 9)
        .padding(.bottom, 4)
        .background(DragHandle())
    }

    private var textArea: some View {
        Text(model.text.isEmpty ? " " : model.text + " ")
            .font(font)
            .lineLimit(AppSettings.maxNoteLines)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 5)        
            .fixedSize(horizontal: false, vertical: true)
            .opacity(0)
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    if model.text.isEmpty {
                        Text("New note")
                            .font(font)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $model.text)
                        .font(font)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.never)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
    }

    private var statusText: String {
        guard let left = model.secondsLeft else { return "Pinned" }
        let seconds = Int(left.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

extension View {
    @ViewBuilder
    func noteGlass(in shape: RoundedRectangle, tint: Color, strength: Double) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular.tint(tint.opacity(strength)), in: shape)
        } else {
            self.background(tint.opacity(strength), in: shape)
                .background(.regularMaterial, in: shape)
                .clipShape(shape)
        }
    }
}

struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}