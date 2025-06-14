# OBIBUF Obitopology Layer

Part of the OBINexus Buffer Protocol (OBIBUF) three-layer architecture.

## Layer Responsibilities

### Topology Layer (obitopology)
- Distributed coordination and governance
- P2P/Bus/Ring/Star/Mesh/Hybrid topology support
- Governance zone management (Autonomous/Warning/Governance)
- Cost function monitoring (C ≤ 0.5 threshold)
- Network failover and redundancy

### Dependencies
- obiprotocol (required)

### Key Components
- `src/core/topology_core.c` - Topology management
- `include/obitopology.h` - Public API definitions
