import AppKit
import SwiftUI

final class NotePanel: NSPanel {
    var onClose: (() -> Void)?
    let model = NoteModel()
    private var hosting: NSHostingView<NoteView>!

    init(topLeft: NSPoint) {
        let width = AppSettings.noteWidth
        let startHeight: CGFloat = 80
        super.init(contentRect: NSRect(x: topLeft.x, y: topLeft.y - startHeight,
                                       width: width, height: startHeight),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = false      
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        let container = HoverTrackingView(frame: NSRect(x: 0, y: 0, width: width, height: startHeight))
        hosting = NSHostingView(rootView: NoteView(model: model, onClose: { [weak self] in
            self?.close()
        }))
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        container.addSubview(hosting)
        container.onHoverChange = { [weak self] hovered in
            self?.model.setHovered(hovered)
        }
        contentView = container

        model.onDimChange = { [weak self] dimmed in
            self?.animateAlpha(to: dimmed ? AppSettings.dimmedAlpha : 1, duration: 0.4)
        }
        model.onFadeOut = { [weak self] in
            self?.animateAlpha(to: 0, duration: 0.9)
        }
        model.onExpire = { [weak self] in
            self?.close()
        }
        model.onTextChange = { [weak self] in
            DispatchQueue.main.async { self?.fitToContent() }
        }

        fitToContent()
        model.start()
    }

    func fitToContent() {
        hosting.layoutSubtreeIfNeeded()
        let newHeight = ceil(hosting.fittingSize.height)
        guard newHeight > 0, abs(newHeight - frame.height) > 0.5 else { return }

        var f = frame
        f.origin.y += f.height - newHeight   
        f.size.height = newHeight
        setFrame(f, display: true)
    }

    override var canBecomeKey: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .rightMouseDown:
            model.registerInteraction()
        case .keyDown:
            model.registerKeyPress()
        default:
            break
        }
        super.sendEvent(event)
    }

    private func animateAlpha(to value: CGFloat, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            self.animator().alphaValue = value
        }
    }

    override func close() {
        model.stop()
        super.close()
        onClose?()
    }
}

final class HoverTrackingView: NSView {
    var onHoverChange: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self,
                                       userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }
}