//
//  PlaybackCodecCapabilities.swift
//  Runner
//
//  BitChord 1.0.8 — Playback Codec Capabilities & Route Suitability
//

import Foundation
import AVFoundation

@MainActor
public final class PlaybackCodecCapabilities {
    public static let shared = PlaybackCodecCapabilities()
    
    public private(set) var allowLosslessSources: Bool = true
    
    public func setLosslessOutput(value: Bool) {
        allowLosslessSources = value
    }
    
    public func canRenderDolby(codec: String?, headers: [String: String] = [:]) -> Bool {
        guard headers.isEmpty else { return false }
        guard AppleDolbyRenderer.available else { return false }
        guard let codec = codec?.lowercased() else { return false }
        return codec.contains("eac3") || codec.contains("e-ac-3") || codec.contains("ec-3") || codec.contains("joc") || codec.contains("atmos")
    }
}
