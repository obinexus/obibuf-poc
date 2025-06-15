#!/bin/bash
# DFA Unit Test Runner

set -e

echo "🧪 Running DFA Unit Tests..."
echo "============================"

# Compile test
gcc -std=c11 -I../../../include -L../../../lib -lobiprotocol \
    test_dfa_basic.c -o test_dfa_basic

# Run test
./test_dfa_basic

echo "✅ DFA unit tests completed"
