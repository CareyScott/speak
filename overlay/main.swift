import AppKit
import AVFoundation

struct Command: Decodable {
    let type: String
    let path: String?
    let index: Int?
    let total: Int?
}

final class WaveView: NSView {
    private let barCount = 21
    private var level: CGFloat = 0
    private var displayed: [CGFloat]
    private var phases: [CGFloat]
    private var tick: CGFloat = 0

    override init(frame: NSRect) {
        displayed = Array(repeating: 0, count: barCount)
        phases = (0..<barCount).map { _ in CGFloat.random(in: 0...(2 * .pi)) }
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func push(_ newLevel: CGFloat) {
        level = max(0, min(1, newLevel))
        tick += 0.35
        needsDisplay = true
    }

    func flatten() {
        level = 0
        needsDisplay = true
    }

    private func weight(_ index: Int) -> CGFloat {
        let centre = CGFloat(barCount - 1) / 2
        let distance = (CGFloat(index) - centre) / centre
        return exp(-distance * distance * 3.2)
    }

    override func draw(_ dirtyRect: NSRect) {
        let barWidth: CGFloat = 2.5
        let gap = (bounds.width - barWidth * CGFloat(barCount)) / CGFloat(barCount - 1)
        NSColor.white.withAlphaComponent(0.92).setFill()
        for index in 0..<barCount {
            let wobble = 0.65 + 0.35 * sin(tick * (0.8 + weight(index)) + phases[index])
            let target = 0.12 + level * weight(index) * wobble
            displayed[index] += (target - displayed[index]) * 0.45
            let height = bounds.height * displayed[index]
            let x = CGFloat(index) * (barWidth + gap)
            let rect = NSRect(x: x, y: (bounds.height - height) / 2, width: barWidth, height: height)
            NSBezierPath(roundedRect: rect, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
        }
    }
}

final class Overlay: NSObject, AVAudioPlayerDelegate {
    private let panel: NSPanel
    private let wave = WaveView()
    private let pauseButton = NSButton()
    private var player: AVAudioPlayer?
    private var currentIndex = 0
    private var holdPaused = false
    private var meterTimer: Timer?

    override init() {
        let size = NSSize(width: 236, height: 52)
        panel = NSPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        panel.appearance = NSAppearance(named: .darkAqua)
        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = root

        let content = NSView(frame: root.bounds)
        content.wantsLayer = true
        content.layer?.cornerRadius = size.height / 2
        content.layer?.cornerCurve = .continuous
        content.layer?.masksToBounds = true
        content.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.92).cgColor
        root.addSubview(content)

        let back = makeButton(symbol: "backward.end.fill", action: #selector(backPressed))
        pauseButton.target = self
        pauseButton.action = #selector(pausePressed)
        styleButton(pauseButton, symbol: "pause.fill")
        let stop = makeButton(symbol: "xmark", action: #selector(stopPressed))

        back.frame = NSRect(x: 12, y: 12, width: 28, height: 28)
        wave.frame = NSRect(x: 48, y: 14, width: 100, height: 24)
        pauseButton.frame = NSRect(x: 156, y: 12, width: 28, height: 28)
        stop.frame = NSRect(x: 196, y: 12, width: 28, height: 28)
        [back, wave, pauseButton, stop].forEach { content.addSubview($0) }

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.minY + 24))
        }
    }

    private func makeButton(symbol: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.target = self
        button.action = action
        styleButton(button, symbol: symbol)
        return button
    }

    private func styleButton(_ button: NSButton, symbol: String) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)
        button.image?.isTemplate = true
        button.contentTintColor = .white
        button.isBordered = false
        button.imageScaling = .scaleProportionallyDown
    }

    func handle(_ command: Command) {
        switch command.type {
        case "play":
            guard let path = command.path, let index = command.index else { return }
            play(path: path, index: index)
        case "pause": pause()
        case "resume": resume()
        case "stop": stopPlayback()
        case "idle":
            hide()
            NSApp.terminate(nil)
        default: break
        }
    }

    private func play(path: String, index: Int) {
        player?.stop()
        currentIndex = index
        guard let next = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) else {
            send(["type": "finished", "index": index])
            return
        }
        next.delegate = self
        next.isMeteringEnabled = true
        next.prepareToPlay()
        player = next
        show()
        if holdPaused { return }
        next.play()
        startMetering()
    }

    private func pause() {
        holdPaused = true
        player?.pause()
        stopMetering()
        setPauseIcon(paused: true)
    }

    private func resume() {
        holdPaused = false
        setPauseIcon(paused: false)
        guard let player else { return }
        player.play()
        startMetering()
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        holdPaused = false
        setPauseIcon(paused: false)
        stopMetering()
    }

    private func show() {
        if !panel.isVisible { panel.orderFrontRegardless(); panel.invalidateShadow() }
    }

    private func hide() {
        stopPlayback()
        panel.orderOut(nil)
    }

    private func setPauseIcon(paused: Bool) {
        styleButton(pauseButton, symbol: paused ? "play.fill" : "pause.fill")
    }

    private func startMetering() {
        stopMetering()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            player.updateMeters()
            let power = player.averagePower(forChannel: 0)
            self.wave.push(CGFloat((power + 50) / 50))
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
        wave.flatten()
    }

    @objc private func backPressed() {
        player?.stop()
        player = nil
        stopMetering()
        holdPaused = false
        setPauseIcon(paused: false)
        send(["type": "back", "index": currentIndex])
    }

    @objc private func pausePressed() {
        holdPaused ? resume() : pause()
        send(["type": holdPaused ? "paused" : "resumed"])
    }

    @objc private func stopPressed() {
        hide()
        send(["type": "stop"])
    }

    func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        guard finished === player else { return }
        stopMetering()
        send(["type": "finished", "index": currentIndex])
    }

    private func send(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write("\n".data(using: .utf8)!)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let overlay = Overlay()

Thread.detachNewThread {
    while let line = readLine() {
        guard let data = line.data(using: .utf8), let command = try? JSONDecoder().decode(Command.self, from: data) else { continue }
        DispatchQueue.main.async { overlay.handle(command) }
    }
    DispatchQueue.main.async { app.terminate(nil) }
}

app.run()
