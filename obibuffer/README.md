# OBIBUF Obibuffer Layer

Part of the OBINexus Buffer Protocol (OBIBUF) three-layer architecture.

## Layer Responsibilities

### Buffer Layer (obibuffer)
- CLI interface and command processing
- Message validation and schema enforcement
- Audit trail generation (NASA-STD-8739.8 compliance)
- Buffer size management (max 8192 bytes)
- Integration with Python bindings

### Dependencies
- obitopology (required)
- obiprotocol (transitive dependency)

### Key Components
- `src/core/buffer_core.c` - Buffer management
- `include/obibuffer.h` - Public API definitions
