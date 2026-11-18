import AuraBeatCore
import AudioDSP
import SwiftUI

/// Dedicated Spatial Audio controller screen with interactive soundstage visualization and acoustic presets.
struct SpatialAudioScreen: View {
    @Environment(AppSettings.self) private var settings
    @Environment(PlayerController.self) private var player

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(spacing: 20) {
                // Interactive Soundstage Visualizer
                SoundstageVisualizer(
                    isEnabled: settings.spatialAudio,
                    width: settings.spatialAudioWidth,
                    depth: settings.spatialAudioDepth,
                    intensity: settings.spatialAudioIntensity
                )
                .frame(height: 190)
                .padding(.horizontal)
                .padding(.top, 8)

                // Master Toggle Group
                SettingsGroup {
                    SettingsToggleRow(
                        symbol: "dot.radiowaves.left.and.right",
                        title: L10n.spatialAudio,
                        subtitle: settings.spatialAudio ? "Active on stereo headphone output" : "Bypassed (bit-exact original stereo)",
                        isOn: $settings.spatialAudio
                    )
                }

                if settings.spatialAudio {
                    // Acoustic Presets
                    SettingsGroup(header: "Acoustic Presets", footer: settings.spatialAudioPreset.subtitle) {
                        Picker("Preset", selection: $settings.spatialAudioPreset) {
                            ForEach(SpatialAudioPreset.allCases) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 6)
                    }

                    // Fine-Tuning Sliders
                    SettingsGroup(header: "Spatial Tuning") {
                        // Intensity Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Spatial Intensity", systemImage: "waveform")
                                    .font(AppTheme.Typeface.body)
                                Spacer()
                                Text("\(Int(settings.spatialAudioIntensity * 100))%")
                                    .font(AppTheme.Typeface.label)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { settings.spatialAudioIntensity },
                                set: {
                                    settings.spatialAudioPreset = .custom
                                    settings.spatialAudioIntensity = $0
                                }
                            ), in: 0.1...1.0, step: 0.05)
                            .tint(Color.accentColor)
                        }
                        .padding(.vertical, 4)

                        // Stereo Width Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Stereo Spatial Width", systemImage: "arrow.left.and.right")
                                    .font(AppTheme.Typeface.body)
                                Spacer()
                                Text("\(Int(settings.spatialAudioWidth * 100))%")
                                    .font(AppTheme.Typeface.label)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { settings.spatialAudioWidth },
                                set: {
                                    settings.spatialAudioPreset = .custom
                                    settings.spatialAudioWidth = $0
                                }
                            ), in: 1.0...2.2, step: 0.05)
                            .tint(Color.accentColor)
                        }
                        .padding(.vertical, 4)

                        // Ambience Depth Slider
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Acoustic Depth & Crossfeed", systemImage: "rays")
                                    .font(AppTheme.Typeface.body)
                                Spacer()
                                Text("\(Int(settings.spatialAudioDepth * 100))%")
                                    .font(AppTheme.Typeface.label)
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: Binding(
                                get: { settings.spatialAudioDepth },
                                set: {
                                    settings.spatialAudioPreset = .custom
                                    settings.spatialAudioDepth = $0
                                }
                            ), in: 0.0...1.0, step: 0.05)
                            .tint(Color.accentColor)
                        }
                        .padding(.vertical, 4)
                    }

                    // Reset Button
                    Button(role: .cancel, action: {
                        withAnimation {
                            settings.resetSpatialAudio()
                            settings.spatialAudio = true
                        }
                    }) {
                        Label("Reset to Natural Defaults", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                }

                // Architecture & Technology Notice
                SettingsGroup(footer: "AuraBeat Spatial Audio uses high-precision binaural crossfeed (Interaural Time Difference modeling) and dynamic Mid/Side acoustic matrixing with soft-saturation headroom protection. Dolby Atmos streams automatically bypass this processor for hardware bitstream passthrough.") {
                    SettingsRow(
                        symbol: "info.circle",
                        title: "Binaural DSP Architecture",
                        subtitle: "Engine: 64-bit CoreAudio processing tap with zero latency"
                    )
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(L10n.spatialAudio)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Visual representation of the stereo soundstage and listener position.
private struct SoundstageVisualizer: View {
    var isEnabled: Bool
    var width: Float
    var depth: Float
    var intensity: Float

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.72)
                let primaryColor = isEnabled ? Color.accentColor : Color.secondary.opacity(0.35)

                // Depth Ambience Rings
                if isEnabled {
                    let rings = 3
                    for i in 1...rings {
                        let radius = CGFloat(38 + i * 26) * CGFloat(0.8 + depth * 0.4)
                        let ringPath = Path(ellipseIn: CGRect(
                            x: center.x - radius,
                            y: center.y - radius * 0.65,
                            width: radius * 2,
                            height: radius * 1.3
                        ))
                        context.stroke(
                            ringPath,
                            with: .color(primaryColor.opacity(Double(0.35 / Double(i)))),
                            lineWidth: 1.5
                        )
                    }
                }

                // Listener Head (Center)
                let headRect = CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32)
                context.fill(Path(ellipseIn: headRect), with: .color(Color(.systemBackground)))
                context.stroke(Path(ellipseIn: headRect), with: .color(primaryColor), lineWidth: 2)

                // Virtual Left and Right Speakers / Acoustic Soundstage
                let spread = CGFloat(45 + (width - 1.0) * 80)
                let leftSpeaker = CGPoint(x: center.x - spread, y: center.y - CGFloat(55 + depth * 35))
                let rightSpeaker = CGPoint(x: center.x + spread, y: center.y - CGFloat(55 + depth * 35))

                // Left Speaker
                drawSpeaker(context: &context, at: leftSpeaker, color: primaryColor, label: "L")
                // Right Speaker
                drawSpeaker(context: &context, at: rightSpeaker, color: primaryColor, label: "R")

                // Center Soundstage Arc
                var arc = Path()
                arc.move(to: leftSpeaker)
                arc.addQuadCurve(
                    to: rightSpeaker,
                    control: CGPoint(x: center.x, y: center.y - CGFloat(85 + depth * 45))
                )
                context.stroke(
                    arc,
                    with: .color(primaryColor.opacity(isEnabled ? 0.6 : 0.2)),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                )
            }

            VStack {
                HStack {
                    Text(isEnabled ? "BINAURAL SPATIAL AUDIO" : "STEREO BYPASS")
                        .font(AppTheme.Typeface.labelSmall)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                    Spacer()
                }
                Spacer()
            }
            .padding(14)
        }
    }

    private func drawSpeaker(context: inout GraphicsContext, at point: CGPoint, color: Color, label: String) {
        let rect = CGRect(x: point.x - 12, y: point.y - 12, width: 24, height: 24)
        context.fill(Path(ellipseIn: rect), with: .color(color))
        context.draw(
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(.white),
            at: point
        )
    }
}
