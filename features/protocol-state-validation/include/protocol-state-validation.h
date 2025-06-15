/*
 * protocol-state-validation - OBIBUF Feature Header
 * OBINexus Computing - Aegis Framework
 * Generated: 2025-06-15T00:23:54+01:00
 */

#ifndef PROTOCOL-STATE-VALIDATION_H
#define PROTOCOL-STATE-VALIDATION_H

#include "obiprotocol.h"
#include "obitopology.h"
#include "obibuffer.h"

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Feature result codes
typedef enum {
    PROTOCOL-STATE-VALIDATION_SUCCESS = 0,
    PROTOCOL-STATE-VALIDATION_ERROR_INVALID_INPUT,
    PROTOCOL-STATE-VALIDATION_ERROR_VALIDATION_FAILED,
    PROTOCOL-STATE-VALIDATION_ERROR_DEPENDENCY_FAILURE
} protocol-state-validation_result_t;

// Core API functions
protocol-state-validation_result_t protocol-state-validation_init(void);
void protocol-state-validation_cleanup(void);
protocol-state-validation_result_t protocol-state-validation_process(const uint8_t *data, size_t length);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* PROTOCOL-STATE-VALIDATION_H */
