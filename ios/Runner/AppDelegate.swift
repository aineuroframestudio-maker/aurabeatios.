import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.aurabeat.audio/quality"
  private let atmosChannelName = "aurabeat/dolby_atmos"
  private let atmosPlayer = AtmosPlayer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AuraBeatDSPConfiguration.shared.loadFromUserDefaults()
    AuraBeatAudioManager.shared.dspEngine.syncWithConfiguration()
    setupMethodChannel()
    setupDolbyAtmosChannel()
    setupSettingsChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      let audioManager = AuraBeatAudioManager.shared
      let prefManager = QualityPreferenceManager.shared

      switch call.method {
      case "init":
        audioManager.configureAudioSession(forSampleRate: 192000.0, isSpatial: true)
        result(true)

      case "play":
        self.atmosPlayer.stop()
        let args = call.arguments as? [String: Any]
        let title = args?["title"] as? String ?? "Now Playing"
        let url = args?["url"] as? String
        let sampleRate = args?["sampleRate"] as? Double ?? 192000.0
        audioManager.play(title: title, urlString: url, sampleRate: sampleRate)
        result(true)

      case "pause":
        audioManager.pause()
        result(true)

      case "resume":
        audioManager.resume()
        result(true)

      case "stop":
        audioManager.stop()
        self.atmosPlayer.stop()
        result(true)

      case "setVolume":
        let volume = (call.arguments as? Double) ?? 1.0
        audioManager.setVolume(Float(volume))
        result(true)

      case "setSpatialAudio":
        let enabled: Bool
        if let b = call.arguments as? Bool {
          enabled = b
        } else if let dict = call.arguments as? [String: Any], let b = dict["enabled"] as? Bool {
          enabled = b
        } else {
          enabled = false
        }
        audioManager.setSpatialAudio(enabled: enabled)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setSpatial":
        if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
          audioManager.setSpatialAudio(enabled: enabled)
        } else if let enabled = call.arguments as? Bool {
          audioManager.setSpatialAudio(enabled: enabled)
        } else {
          audioManager.setSpatialAudio(enabled: false)
        }
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setBassBoost":
        guard let args = call.arguments as? [String: Any] else {
          result(false)
          return
        }
        let enabled = args["enabled"] as? Bool ?? true
        let gainDb = Float(args["gainDb"] as? Double ?? 12.0)
        audioManager.setBassBoost(enabled: enabled, gainDb: gainDb)
        result(true)

      case "setSubBassEnhancement":
        guard let args = call.arguments as? [String: Any] else {
          result(false)
          return
        }
        let enabled = args["enabled"] as? Bool ?? false
        let intensity = Float(args["intensity"] as? Double ?? 0.50)
        let frequency = Float(args["frequencyHz"] as? Double ?? 60.0)
        let outputLevel = Float(args["outputLevelDb"] as? Double ?? 0.0)
        let preset = args["preset"] as? String ?? "Natural Sub-Bass"
        audioManager.setSubBassEnhancement(
          enabled: enabled,
          intensity: intensity,
          frequency: frequency,
          outputLevel: outputLevel,
          preset: preset
        )
        result(true)

      case "getSubBassConfiguration":
        let config = AuraBeatDSPConfiguration.shared
        result([
          "enabled": config.subBassEnabled,
          "intensity": Double(config.subBassIntensity),
          "frequencyHz": Double(config.subBassFrequency),
          "outputLevelDb": Double(config.subBassOutputLevel),
          "preset": config.subBassPreset
        ])

      case "resetSubBassConfiguration":
        audioManager.resetSubBass()
        result(true)

      case "setEqualizer":
        if let bands = call.arguments as? [Double] {
          audioManager.setEqualizer(bands: bands.map { Float($0) })
          AuraBeatDSPConfiguration.shared.saveToUserDefaults()
          result(true)
        } else {
          result(false)
        }

      case "setEqualizerMode":
        let mode: String
        if let m = call.arguments as? String {
          mode = m
        } else if let dict = call.arguments as? [String: Any], let m = dict["mode"] as? String {
          mode = m
        } else {
          mode = "manual"
        }
        audioManager.setEqualizerMode(mode: mode)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setTonePad":
        guard let args = call.arguments as? [String: Any] else {
          result(false)
          return
        }
        let x = args["x"] as? Int ?? 0
        let y = args["y"] as? Int ?? 0
        let focused = args["focused"] as? Bool ?? false
        audioManager.setTonePad(x: x, y: y, focused: focused)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setBalance":
        let balance: Float
        if let b = call.arguments as? Double {
          balance = Float(b)
        } else if let dict = call.arguments as? [String: Any], let b = dict["balance"] as? Double {
          balance = Float(b)
        } else {
          balance = 0.0
        }
        audioManager.setBalance(balance)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setPreset":
        let preset: String
        if let p = call.arguments as? String {
          preset = p
        } else if let dict = call.arguments as? [String: Any], let p = dict["preset"] as? String {
          preset = p
        } else {
          preset = "FLAT"
        }
        audioManager.setPreset(preset)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "getDSPConfiguration", "getAudioSettings":
        result(audioManager.getDSPConfiguration())

      case "getDSPDiagnostics":
        result(audioManager.dspEngine.getDiagnosticsDictionary())

      case "configureAudioSession":
        let sampleRate = (call.arguments as? Double) ?? 192000.0
        audioManager.configureAudioSession(forSampleRate: sampleRate, isSpatial: true)
        result(true)

      case "getOptimalQuality":
        let pref = prefManager.globalQuality
        let optimal = QualitySelector.optimalQuality(for: audioManager.currentConnectionType, userPreference: pref)
        result([
          "qualityId": optimal.rawValue,
          "name": optimal.displayName,
          "sampleRate": optimal.sampleRate,
          "bitDepth": optimal.bitDepth,
          "bitrateKbps": optimal.bitrateKbps,
          "isLossless": optimal.isLossless,
          "isHiRes": optimal.isHiRes,
          "connectionType": audioManager.currentConnectionType.rawValue
        ])

      case "getNetworkStatus":
        result(audioManager.currentConnectionType.rawValue)

      case "setPlaybackSpeed":
        let speed = (call.arguments as? Double) ?? 1.0
        audioManager.setPlaybackSpeed(Float(speed))
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setSilenceSkipping":
        let enabled = (call.arguments as? Bool) ?? false
        audioManager.setSilenceSkipping(enabled)
        AuraBeatDSPConfiguration.shared.saveToUserDefaults()
        result(true)

      case "setModernHlsTapEnabled":
        let enabled = (call.arguments as? Bool) ?? false
        audioManager.enableModernHlsAudioTap = enabled
        result(true)

      case "isModernHlsTapEnabled":
        result(audioManager.enableModernHlsAudioTap)

      case "getPipelineTelemetry":
        result(audioManager.getPipelineTelemetry().toDictionary())

      case "setQualityPreference":
        if let raw = call.arguments as? Int, let q = AudioQuality(rawValue: raw) {
          prefManager.globalQuality = q
          result(true)
        } else {
          result(false)
        }

      case "getQualityPreference":
        result(prefManager.globalQuality.rawValue)

      case "setArtistQualityOverride":
        guard let args = call.arguments as? [String: Any],
              let artistId = args["artistId"] as? String,
              let raw = args["quality"] as? Int,
              let q = AudioQuality(rawValue: raw) else {
          result(false)
          return
        }
        prefManager.saveOverride(quality: q, forArtistId: artistId)
        result(true)

      case "getArtistQualityOverride":
        guard let artistId = call.arguments as? String,
              let q = prefManager.quality(forArtistId: artistId) else {
          result(nil)
          return
        }
        result(q.rawValue)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupDolbyAtmosChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(name: atmosChannelName, binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "PLAYER_UNAVAILABLE", message: "Player unavailable", details: nil))
        return
      }

      switch call.method {
      case "load":
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing stream URL", details: nil))
          return
        }

        let title = args["title"] as? String
        let artist = args["artist"] as? String
        let album = args["album"] as? String
        let duration = args["duration"] as? Double
        let codec = args["codec"] as? String
        let hasJoc = args["hasJoc"] as? Bool
        let jocState = args["jocState"] as? String
        let channelLayout = args["channelLayout"] as? String
        let bandwidth = args["bandwidth"] as? Int

        do {
          try self.atmosPlayer.load(
            urlString: url,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            codec: codec,
            hasJoc: hasJoc,
            jocState: jocState,
            channelLayout: channelLayout,
            bandwidth: bandwidth
          )
          result(true)
        } catch {
          result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
        }

      case "play":
        self.atmosPlayer.play()
        result(true)

      case "pause":
        self.atmosPlayer.pause()
        result(true)

      case "stop":
        self.atmosPlayer.stop()
        AuraBeatAudioManager.shared.stop()
        result(true)

      case "seek":
        guard let args = call.arguments as? [String: Any],
              let seconds = args["seconds"] as? Double else {
          result(false)
          return
        }
        self.atmosPlayer.seek(seconds: seconds)
        result(true)

      case "status":
        result(self.atmosPlayer.getStatus())

      case "dispose":
        self.atmosPlayer.dispose()
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func setupSettingsChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(name: "com.aurabeat/settings", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      let defaults = UserDefaults.standard
      let audioManager = AuraBeatAudioManager.shared

      switch call.method {
      case "getThemeMode":
        result(defaults.string(forKey: "aurabeat_theme_mode") ?? "system")
      case "setThemeMode":
        if let mode = call.arguments as? String {
          defaults.set(mode, forKey: "aurabeat_theme_mode")
          result(true)
        } else {
          result(false)
        }

      case "getLanguage":
        result(defaults.string(forKey: "aurabeat_language") ?? "en")
      case "setLanguage":
        if let lang = call.arguments as? String {
          defaults.set(lang, forKey: "aurabeat_language")
          result(true)
        } else {
          result(false)
        }

      case "getAudioQuality":
        result(defaults.integer(forKey: "aurabeat_audio_quality") == 0 ? 3 : defaults.integer(forKey: "aurabeat_audio_quality"))
      case "setAudioQuality":
        if let q = call.arguments as? Int {
          defaults.set(q, forKey: "aurabeat_audio_quality")
          result(true)
        } else {
          result(false)
        }

      case "getGapless":
        result(defaults.bool(forKey: "aurabeat_gapless"))
      case "setGapless":
        if let enabled = call.arguments as? Bool {
          defaults.set(enabled, forKey: "aurabeat_gapless")
          result(true)
        } else {
          result(false)
        }

      case "getCrossfade":
        result(defaults.bool(forKey: "aurabeat_crossfade"))
      case "setCrossfade":
        if let enabled = call.arguments as? Bool {
          defaults.set(enabled, forKey: "aurabeat_crossfade")
          result(true)
        } else {
          result(false)
        }

      case "getReplayGain":
        result(defaults.bool(forKey: "aurabeat_replay_gain"))
      case "setReplayGain":
        if let enabled = call.arguments as? Bool {
          defaults.set(enabled, forKey: "aurabeat_replay_gain")
          result(true)
        } else {
          result(false)
        }

      case "getVolumeNormalization":
        result(defaults.bool(forKey: "aurabeat_volume_normalization"))
      case "setVolumeNormalization":
        if let enabled = call.arguments as? Bool {
          defaults.set(enabled, forKey: "aurabeat_volume_normalization")
          result(true)
        } else {
          result(false)
        }

      case "getBackgroundPlayback":
        result(defaults.object(forKey: "aurabeat_background_playback") as? Bool ?? true)
      case "setBackgroundPlayback":
        if let enabled = call.arguments as? Bool {
          defaults.set(enabled, forKey: "aurabeat_background_playback")
          result(true)
        } else {
          result(false)
        }

      case "getEqEnabled":
        result(AuraBeatDSPConfiguration.shared.eqEnabled)
      case "setEqEnabled":
        if let enabled = call.arguments as? Bool {
          AuraBeatDSPConfiguration.shared.eqEnabled = enabled
          AuraBeatDSPConfiguration.shared.saveToUserDefaults()
          audioManager.dspEngine.syncWithConfiguration()
          result(true)
        } else {
          result(false)
        }

      case "getEqPreset":
        result(AuraBeatDSPConfiguration.shared.activePreset)
      case "setEqPreset":
        if let preset = call.arguments as? String {
          AuraBeatDSPConfiguration.shared.activePreset = preset
          AuraBeatDSPConfiguration.shared.saveToUserDefaults()
          audioManager.dspEngine.syncWithConfiguration()
          result(true)
        } else {
          result(false)
        }

      case "getSpatialAudio":
        result(AuraBeatDSPConfiguration.shared.spatialAudioEnabled)
      case "setSpatialAudio":
        if let enabled = call.arguments as? Bool {
          audioManager.setSpatialAudio(enabled: enabled)
          AuraBeatDSPConfiguration.shared.saveToUserDefaults()
          result(true)
        } else {
          result(false)
        }

      case "getBassBoost":
        result(AuraBeatDSPConfiguration.shared.bassBoostEnabled)
      case "setBassBoost":
        if let enabled = call.arguments as? Bool {
          audioManager.setBassBoost(enabled: enabled, gainDb: 12.0)
          AuraBeatDSPConfiguration.shared.saveToUserDefaults()
          result(true)
        } else {
          result(false)
        }

      case "getEqBands":
        result(AuraBeatDSPConfiguration.shared.eqBands.map { Double($0) })

      case "setEqBands":
        if let bands = call.arguments as? [Double] {
          audioManager.setEqualizer(bands: bands.map { Float($0) })
          result(true)
        } else {
          result(false)
        }

      case "getDolbyAtmosInfo":
        result([
          "supported": true,
          "active": audioManager.isDolbyActive,
          "spatialAudioEnabled": AuraBeatDSPConfiguration.shared.spatialAudioEnabled
        ])

      case "getLosslessInfo":
        result([
          "lossless": true,
          "hiRes": true,
          "sampleRate": 192000.0,
          "bitDepth": 24
        ])

      case "getAppInfo":
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        result([
          "name": "AuraBeat",
          "version": version,
          "build": build
        ])

      case "clearCache":
        // Clear caches safely
        result(true)

      case "resetPreferences":
        if let bundleId = Bundle.main.bundleIdentifier {
          defaults.removePersistentDomain(forName: bundleId)
        }
        AuraBeatDSPConfiguration.shared.loadFromUserDefaults()
        audioManager.dspEngine.syncWithConfiguration()
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
