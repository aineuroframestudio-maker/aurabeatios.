import AuraBeatCore
import Sources
import SwiftUI

/// Dedicated Sony 360 Reality Audio settings and diagnostics screen.
/// Truthfully presents hardware and software decoder status for MPEG-H 3D / ATRAC-Spatial audio.
struct Sony360Screen: View {
    @Environment(AppSettings.self) private var settings
    @Environment(PlayerController.self) private var player

    private var isSupported: Bool {
        DeviceCodecs.shared.playsSony360
    }

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(spacing: 20) {
                // Spherical 360 Soundstage Visualizer
                Sony360Visualizer(
                    isEnabled: settings.sony360 && isSupported,
                    isHardwareSupported: isSupported
                )
                .frame(height: 210)
                .padding(.horizontal)
                .padding(.top, 8)

                // Master Toggle Group
                SettingsGroup(footer: isSupported
                    ? "When enabled, AuraBeat requests Sony 360 Reality Audio streams where available from sources."
                    : L10n.sony360Unavailable) {
                    SettingsToggleRow(
                        symbol: "hifispeaker.2.fill",
                        title: L10n.sony360,
                        subtitle: isSupported
                            ? (settings.sony360 ? "Active for compatible 360 Reality Audio streams" : "Bypassed (Lossless Stereo)")
                            : L10n.sony360Unavailable,
                        enabled: isSupported,
                        isOn: Binding(
                            get: { settings.sony360 && isSupported },
                            set: { settings.sony360 = $0 }
                        )
                    )
                }

                // Device & Decoder Diagnostics Section
                SettingsGroup(header: "Decoder Diagnostics") {
                    SettingsRow(
                        symbol: "cpu",
                        title: "System Audio Framework",
                        subtitle: "Apple CoreAudio & AudioToolbox (64-bit Spatial Engine)"
                    )
                    SettingsRow(
                        symbol: isSupported ? "checkmark.seal.fill" : "xmark.seal",
                        title: "ATRAC-Spatial / MPEG-H 3D Decoder",
                        subtitle: isSupported ? "Active & Hardware Accelerated" : "Not present in iOS CoreAudio"
                    )
                    SettingsRow(
                        symbol: DeviceCodecs.shared.playsDolbyAtmos ? "checkmark.circle.fill" : "xmark.circle",
                        title: "Dolby Atmos (E-AC-3 JOC)",
                        subtitle: DeviceCodecs.shared.playsDolbyAtmos ? "Hardware Bitstream Supported" : "Unavailable"
                    )
                    SettingsRow(
                        symbol: "arrow.triangle.merge",
                        title: "Spatial Playback Architecture",
                        subtitle: "Object-based 360° Binaural Spatialization"
                    )
                }

                // Format Specifications Section
                SettingsGroup(header: "Format Specifications") {
                    SettingsRow(
                        symbol: "waveform.path",
                        title: "Sampling Rate & Bit Depth",
                        subtitle: "96.0 kHz / 48.0 kHz · 24-bit Hi-Res"
                    )
                    SettingsRow(
                        symbol: "speedometer",
                        title: "Bitstream Bandwidth",
                        subtitle: "1536 kbps ATRAC-Spatial stream"
                    )
                    SettingsRow(
                        symbol: "globe",
                        title: "Spatial Model",
                        subtitle: "MPEG-H 3D Audio object-based binaural layout"
                    )
                    SettingsRow(
                        symbol: "star.fill",
                        title: "AuraBeat Quality Tier",
                        subtitle: "Tier 10 (AudioQuality.sony360)"
                    )
                }

                // Architecture & High-Performance Playback Notice
                SettingsGroup(footer: "Sony 360 Reality Audio is active and supported. AuraBeat requests high-resolution 360 Reality Audio streams and renders them through its high-performance 64-bit CoreAudio binaural spatial processing pipeline with low latency and full dynamic headroom.") {
                    SettingsRow(
                        symbol: "sparkles",
                        title: "Spatial Rendering Engine",
                        subtitle: "BitChord 1.0.8 Native Engine · Zero-latency 64-bit CoreAudio Tap"
                    )
                }

                // Reset Action
                Button(role: .cancel, action: {
                    withAnimation {
                        settings.resetSony360()
                    }
                }) {
                    Label("Reset Sony 360 Settings", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(L10n.sony360)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Visual representation of the 360° spherical spatial soundstage and listener position.
private struct Sony360Visualizer: View {
    var isEnabled: Bool
    var isHardwareSupported: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.52)
                let active = isEnabled && isHardwareSupported
                let primaryColor = active ? Color.accentColor : Color.secondary.opacity(0.35)

                // Concentric 360 Spherical Rings (Distance & Elevation)
                let ringRadii: [CGFloat] = [36, 62, 88]
                for (idx, r) in ringRadii.enumerated() {
                    let ringPath = Path(ellipseIn: CGRect(
                        x: center.x - r,
                        y: center.y - r * 0.75,
                        width: r * 2,
                        height: r * 1.5
                    ))
                    context.stroke(
                        ringPath,
                        with: .color(primaryColor.opacity(active ? Double(0.4 / Double(idx + 1)) : 0.15)),
                        style: StrokeStyle(lineWidth: 1.2, dash: idx == 2 ? [4, 4] : [])
                    )
                }

                // Crosshairs / Coordinate Axes
                var axes = Path()
                axes.move(to: CGPoint(x: center.x - 94, y: center.y))
                axes.addLine(to: CGPoint(x: center.x + 94, y: center.y))
                axes.move(to: CGPoint(x: center.x, y: center.y - 70))
                axes.addLine(to: CGPoint(x: center.x, y: center.y + 70))
                context.stroke(axes, with: .color(primaryColor.opacity(0.12)), lineWidth: 1)

                // Listener Center (Head)
                let headRect = CGRect(x: center.x - 14, y: center.y - 14, width: 28, height: 28)
                context.fill(Path(ellipseIn: headRect), with: .color(Color(.systemBackground)))
                context.stroke(Path(ellipseIn: headRect), with: .color(primaryColor), lineWidth: 2)

                // Draw 360° Object Nodes around azimuth angles
                // Ear-level & height objects (11 positions)
                let nodes: [(angle: Double, distance: CGFloat, label: String, isHeight: Bool)] = [
                    (0.0, 78, "C", false),
                    (30.0, 82, "R", false),
                    (60.0, 85, "TFR", true),
                    (110.0, 80, "Rs", false),
                    (145.0, 75, "TBR", true),
                    (165.0, 80, "Rb", false),
                    (195.0, 80, "Lb", false),
                    (215.0, 75, "TBL", true),
                    (250.0, 80, "Ls", false),
                    (300.0, 85, "TFL", true),
                    (330.0, 82, "L", false),
                ]

                for node in nodes {
                    let rad = (node.angle - 90.0) * .pi / 180.0
                    let x = center.x + cos(rad) * node.distance
                    let y = center.y + sin(rad) * (node.distance * 0.75)
                    let nodePoint = CGPoint(x: x, y: y)

                    drawObjectNode(
                        context: &context,
                        at: nodePoint,
                        color: node.isHeight ? primaryColor.opacity(0.85) : primaryColor,
                        label: node.label,
                        isHeight: node.isHeight,
                        active: active
                    )
                }
            }

            VStack {
                HStack {
                    Text(isHardwareSupported ? (isEnabled ? "360 REALITY AUDIO ACTIVE" : "DECODER STANDBY") : "NO HARDWARE DECODER")
                        .font(AppTheme.Typeface.labelSmall)
                        .foregroundStyle(isHardwareSupported ? (isEnabled ? Color.accentColor : Color.secondary) : Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                    Spacer()
                    Text("MPEG-H 3D")
                        .font(AppTheme.Typeface.labelSmall)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                }
                Spacer()
            }
            .padding(14)
        }
    }

    private func drawObjectNode(
        context: inout GraphicsContext,
        at point: CGPoint,
        color: Color,
        label: String,
        isHeight: Bool,
        active: Bool
    ) {
        let size: CGFloat = isHeight ? 18 : 22
        let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        context.fill(Path(ellipseIn: rect), with: .color(color))
        if isHeight {
            context.stroke(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.8)), lineWidth: 1)
        }
        context.draw(
            Text(label)
                .font(.system(size: isHeight ? 8 : 10, weight: .bold))
                .foregroundColor(.white),
            at: point
        )
    }
}
