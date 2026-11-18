#!/bin/zsh
# Build and run the AuraBeatKit package tests on the Mac host (fast, no simulator).
#   scripts/kit-test.sh                      # every module
#   scripts/kit-test.sh --filter LyricsTests # one module's tests
set -euo pipefail
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
cd "$(dirname "$0")/../AuraBeatKit"
git config --global url."https://github.com/mobilyze-llc/onnxruntime-swift-package-manager.git".insteadOf "https://github.com/microsoft/onnxruntime-swift-package-manager.git" || true
git config --global url."https://github.com/mobilyze-llc/onnxruntime-swift-package-manager".insteadOf "https://github.com/microsoft/onnxruntime-swift-package-manager" || true
swift test -j "${JOBS:-3}" "$@"
