/*
 * OBI Buffer Layer - CLI Interface Header
 * Message validation and command-line interface
 * Depends on obitopology and obiprotocol layers
 */

#ifndef OBIBUFFER_H
#define OBIBUFFER_H

#include "obitopology.h"
#include "obiprotocol.h"
#include <stdint.h>
#include <stdbool.h>

// Buffer definitions
#define OBI_MAX_BUFFER_SIZE 8192

typedef struct obi_buffer obi_buffer_t;
typedef struct obi_validator obi_validator_t;

// Result codes
typedef enum {
    OBI_BUFFER_SUCCESS = 0,
    OBI_BUFFER_ERROR_INVALID_SIZE,
    OBI_BUFFER_ERROR_VALIDATION_FAILED,
    OBI_BUFFER_ERROR_TOPOLOGY_DEPENDENCY
} obi_buffer_result_t;

// Core API functions
obi_buffer_result_t obi_buffer_init(obi_topology_context_t *topology_ctx);
void obi_buffer_cleanup(void);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBIBUFFER_H */
