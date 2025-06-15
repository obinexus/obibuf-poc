#!/bin/bash
# Unit Test Runner for protocol-state-validation
# OBINexus Computing - Aegis Framework

set -e

echo "Running unit tests for protocol-state-validation..."

# Compile and run unit tests
gcc -std=c11 -I../../include -I../../../../obiprotocol/include \
    -L../../lib -lprotocol-state-validation \
    test_protocol-state-validation_core.c -o test_protocol-state-validation_core.exe

./test_protocol-state-validation_core.exe

echo "Unit tests completed successfully"

