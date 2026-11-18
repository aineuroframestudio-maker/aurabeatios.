import Foundation

/// Curated acoustic presets for AuraBeat's binaural spatial audio processing.
public enum SpatialAudioPreset: Int, Codable, Hashable, CaseIterable, Identifiable, Sendable {
    /// Subtle, fatigue-free binaural crossfeed modeled after natural acoustic head shadow (ITD ~0.4 ms).
    case natural = 0
    /// Expansive, outward stereo soundstage with wider separation for live and electronic tracks.
    case wide = 1
    /// Three-dimensional acoustic room ambience simulating a live concert hall.
    case concert = 2
    /// Precise, analytical stereo imaging with crisp center vocal localization.
    case studio = 3
    /// Full user control over intensity, stereo width, and ambience depth.
    case custom = 4

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .natural: return "Natural"
        case .wide: return "Wide Soundstage"
        case .concert: return "Concert Hall"
        case .studio: return "Studio Monitor"
        case .custom: return "Custom"
        }
    }

    public var subtitle: String {
        switch self {
        case .natural: return "Natural headphone crossfeed to prevent listening fatigue"
        case .wide: return "Expansive stereo panorama with enhanced side clarity"
        case .concert: return "Three-dimensional acoustic room presence and depth"
        case .studio: return "Crisp center localization with balanced stereo field"
        case .custom: return "Fine-tune width, depth, and spatial intensity"
        }
    }

    public var defaultWidth: Float {
        switch self {
        case .natural: return 1.8
        case .wide: return 2.2
        case .concert: return 2.5
        case .studio: return 1.4
        case .custom: return 2.0
        }
    }

    public var defaultDepth: Float {
        switch self {
        case .natural: return 0.40
        case .wide: return 0.55
        case .concert: return 0.75
        case .studio: return 0.20
        case .custom: return 0.50
        }
    }

    public var defaultIntensity: Float {
        switch self {
        case .natural: return 0.90
        case .wide: return 1.0
        case .concert: return 1.0
        case .studio: return 0.75
        case .custom: return 1.0
        }
    }
}
