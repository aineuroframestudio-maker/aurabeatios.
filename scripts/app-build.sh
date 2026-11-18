#!/bin/zsh
# Compile the app, widget and all test bundles for the iOS Simulator without booting one.
set -euo pipefail
# Parallel compile jobs are capped at 3 so the machine stays usable during a build (JOBS=n overrides).
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
cd "$(dirname "$0")/.."
git config --global url."https://github.com/mobilyze-llc/onnxruntime-swift-package-manager.git".insteadOf "https://github.com/microsoft/onnxruntime-swift-package-manager.git" || true
git config --global url."https://github.com/mobilyze-llc/onnxruntime-swift-package-manager".insteadOf "https://github.com/microsoft/onnxruntime-swift-package-manager" || true
xcodebuild build-for-testing -workspace AuraBeat.xcworkspace -scheme AuraBeat \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath .derived -jobs "${JOBS:-3}" -quiet "$@"
