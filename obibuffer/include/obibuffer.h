/*
 * OBI Buffer Layer - CLI Interface Header
 * Depends on obitopology and obiprotocol layers
 * Provides message validation and command-line interface
 */

#ifndef OBIBUFFER_H
#define OBIBUFFER_H

#include "obitopology.h"
#include "obiprotocol.h"
#include <stdint.h>
#include <stdbool.h>

// Forward declarations
typedef struct obi_buffer_context obi_buffer_context_t;

// Buffer definitions
#define OBI_MAX_BUFFER_SIZE 8192

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
obi_buffer_context_t* obi_buffer_get_context(void);
obi_buffer_result_t obi_buffer_generate_audit(obi_buffer_context_t *ctx, const char *filename);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBIBUFFER_H */
