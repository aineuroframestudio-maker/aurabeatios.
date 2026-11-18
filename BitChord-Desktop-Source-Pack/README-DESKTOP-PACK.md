# BitChord Desktop Source Pack

This archive is assembled from the supplied BitChord-1.8 source archive.

## Included
- `desktopApp/`: the complete Compose Desktop/JVM application module, including its Kotlin sources, resources, native Windows/Linux bridges, packaging files, and Gradle build script.
- `shared/` and `sharedUi/`: modules directly required by the desktop application.
- Root Gradle settings, build files, wrapper, and desktop documentation.
- `native/analyzer/`, the JNI C++ bridge sources, and ONNX models referenced by the desktop build.

## Excluded
- The Android application source tree (`app/src/main/java`, Android manifests, Android UI/application code, etc.).
- Backend services and unrelated repository assets.

A few files under `app/src/main/` are intentionally included only where the desktop Gradle build directly references them (JNI analyzer bridge and ONNX model assets). Their presence does not mean the Android app module is included.

## Important iOS note
This is a **Desktop source/reference pack**, not an iOS-ready audio engine and not a prebuilt iOS library. Desktop code targets the JVM and uses desktop operating-system APIs and native libraries. Windows-specific WASAPI/Win32/JNI code cannot be copied unchanged into iOS. An iOS port must identify portable DSP/decoding logic and replace platform audio I/O with iOS-native audio APIs, then compile and test it separately.

## Build environment
The repository's `DESKTOP.md` specifies Java 21 for the desktop target. The Gradle wrapper is included. Native analyzer features may additionally require CMake and a suitable C++ toolchain, as described in the desktop Gradle build and documentation.

## License
The upstream `LICENSE` file is included. It states GNU GPL version 3. Preserve applicable copyright and license notices when modifying or redistributing this source.
