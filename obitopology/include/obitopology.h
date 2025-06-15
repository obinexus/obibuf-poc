/*
 * OBI Topology Layer - Network Coordination Header
 * Depends on obiprotocol layer
 * Provides distributed coordination and governance
 */

#ifndef OBITOPOLOGY_H
#define OBITOPOLOGY_H

#include "obiprotocol.h"
#include <stdint.h>
#include <stdbool.h>

// Forward declarations
typedef struct obi_topology_context obi_topology_context_t;
typedef struct obi_topology_metrics obi_topology_metrics_t;

// Topology types
typedef enum {
    OBI_TOPOLOGY_P2P,
    OBI_TOPOLOGY_BUS,
    OBI_TOPOLOGY_RING,
    OBI_TOPOLOGY_STAR,
    OBI_TOPOLOGY_MESH,
    OBI_TOPOLOGY_HYBRID
} obi_topology_type_t;

// Result codes
typedef enum {
    OBI_TOPOLOGY_SUCCESS = 0,
    OBI_TOPOLOGY_ERROR_PROTOCOL_DEPENDENCY,
    OBI_TOPOLOGY_ERROR_INVALID_CONFIG,
    OBI_TOPOLOGY_ERROR_NETWORK_FAILURE
} obi_topology_result_t;

// Metrics structure
struct obi_topology_metrics {
    double cost_function;
    int active_nodes;
    char governance_zone[64];
    bool failover_enabled;
};

// Core API functions
obi_topology_result_t obi_topology_init(obi_protocol_context_t *protocol_ctx);
void obi_topology_cleanup(void);
obi_topology_context_t* obi_topology_get_context(void);
obi_topology_result_t obi_topology_configure(obi_topology_context_t *ctx, obi_topology_type_t type);
obi_topology_result_t obi_topology_get_metrics(obi_topology_context_t *ctx, obi_topology_metrics_t *metrics);
obi_result_t obi_topology_send_message(obi_topology_context_t *ctx, obi_buffer_t *buffer, const char *destination);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBITOPOLOGY_H */
