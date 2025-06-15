#!/bin/bash

# build_obibuf_layers.sh
# Run clean builds for each OBIBUF layer and capture stderr to a log for Claude

set -e

OUTPUT_LOG="build_errors.txt"
> "$OUTPUT_LOG"  # Clear the file

for module in obiprotocol obitopology obibuffer; do
  echo "🔧 Building $module..." | tee -a "$OUTPUT_LOG"
  (
    cd "$module" || { echo "[ERROR] Missing directory: $module" >&2; exit 1; }
    make clean 2>>"../$OUTPUT_LOG"
    make 2>>"../$OUTPUT_LOG"
    cd ..
  )
done

echo "✅ Build script completed. All stderr output saved to $OUTPUT_LOG"
