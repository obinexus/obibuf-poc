#!/bin/bash
# Integration Test Runner for protocol-state-validation
# OBINexus Computing - Aegis Framework

set -e

echo "Running integration tests for protocol-state-validation..."

# Test CLI interface
if [ -f "../../bin/protocol-state-validation.exe" ]; then
    echo "Testing CLI interface..."
    ../../bin/protocol-state-validation.exe --help
    echo "✅ CLI interface test passed"
else
    echo "⚠️  CLI executable not found, skipping CLI tests"
fi

echo "Integration tests completed successfully"

