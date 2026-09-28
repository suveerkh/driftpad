import SwiftUI

final class NoteModel: ObservableObject {
    @Published var text = "" { didSet { onTextChange?() } }
    @Published var isPinned = false { didSet { registerInteraction() } }
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isHovered = false

    var onDimChange: ((Bool) -> Void)?   
    var onFadeOut: (() -> Void)?       
    var onExpire: (() -> Void)?         
    var onTextChange: (() -> Void)?     

    private static let tickInterval: TimeInterval = 0.5
    private var timer: Timer?
    private var dimIdle: TimeInterval = 0
    private var lastKeyPress: Date = .distantPast
    private var lastDimmed = false
    private var isFadingOut = false

    var isDimmed: Bool { !isHovered && dimIdle >= AppSettings.dimDelay }

    var secondsLeft: TimeInterval? {
        isPinned ? nil : max(0, AppSettings.disappearSeconds - elapsed)
    }

    private var isCountdownPaused: Bool {
        isPinned || isHovered || Date().timeIntervalSince(lastKeyPress) < AppSettings.typingPause
    }

    func start() {
        let t = Timer(timeInterval: Self.tickInterval, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)  
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func registerInteraction() {
        dimIdle = 0
        cancelFadeOut()
        updateDim()
    }

    func registerKeyPress() {
        lastKeyPress = Date()
        registerInteraction()
    }

    func setHovered(_ hovered: Bool) {
        isHovered = hovered
        dimIdle = 0
        if hovered { cancelFadeOut() }
        updateDim()
    }

    private func tick() {
        if !isHovered { dimIdle += Self.tickInterval }
        updateDim()

        guard !isCountdownPaused else { return }
        elapsed = min(elapsed + Self.tickInterval, AppSettings.disappearSeconds)

        guard elapsed >= AppSettings.disappearSeconds else { return }
        if !isFadingOut {
            isFadingOut = true
            fadeStartedAt = Date()
            onFadeOut?()                                   
        } else if Date().timeIntervalSince(fadeStartedAt) >= 1 {
            stop()
            onExpire?()                                    
        }
    }

    private var fadeStartedAt: Date = .distantPast

    private func cancelFadeOut() {
        guard isFadingOut else { return }
        isFadingOut = false
        lastDimmed = true     
    }

    private func updateDim() {
        let dimmed = isDimmed
        if dimmed != lastDimmed {
            lastDimmed = dimmed
            onDimChange?(dimmed)
        }
    }
}