# OBIBUF Obiprotocol Layer

Part of the OBINexus Buffer Protocol (OBIBUF) three-layer architecture.

## Layer Responsibilities

### Protocol Layer (obiprotocol)
- DFA automaton engine for pattern recognition
- AEGIS RegexAutomatonEngine implementation
- Zero Trust architecture enforcement
- Canonical state normalization
- Core cryptographic primitives validation

### Dependencies
- None (foundation layer)

### Key Components
- `src/core/protocol_core.c` - Main protocol implementation
- `include/obiprotocol.h` - Public API definitions
