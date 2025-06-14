/*
 * OBI Topology Layer - Distributed Coordination Header
 * Governance zones and topology management
 * Depends on obiprotocol layer
 */

#ifndef OBITOPOLOGY_H
#define OBITOPOLOGY_H

#include "obiprotocol.h"
#include <stdint.h>
#include <stdbool.h>

// Topology definitions
typedef enum {
    OBI_TOPOLOGY_P2P,
    OBI_TOPOLOGY_BUS,
    OBI_TOPOLOGY_RING,
    OBI_TOPOLOGY_STAR,
    OBI_TOPOLOGY_MESH,
    OBI_TOPOLOGY_HYBRID
} obi_topology_type_t;

typedef enum {
    OBI_ZONE_AUTONOMOUS = 0,    // C ≤ 0.5
    OBI_ZONE_WARNING = 1,       // 0.5 < C ≤ 0.6
    OBI_ZONE_GOVERNANCE = 2     // C > 0.6
} obi_governance_zone_t;

typedef struct obi_topology_context obi_topology_context_t;

// Result codes
typedef enum {
    OBI_TOPOLOGY_SUCCESS = 0,
    OBI_TOPOLOGY_ERROR_INVALID_CONFIG,
    OBI_TOPOLOGY_ERROR_GOVERNANCE_VIOLATION,
    OBI_TOPOLOGY_ERROR_PROTOCOL_DEPENDENCY
} obi_topology_result_t;

// Core API functions
obi_topology_result_t obi_topology_init(obi_protocol_context_t *protocol_ctx);
void obi_topology_cleanup(void);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBITOPOLOGY_H */
