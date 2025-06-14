/*
 * OBI Protocol Layer - Core Header
 * DFA automaton and regex-based pattern matching
 * Zero Trust architecture enforcement
 */

#ifndef OBIPROTOCOL_H
#define OBIPROTOCOL_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Core protocol definitions
typedef struct obi_protocol_context obi_protocol_context_t;
typedef struct obi_pattern_registry obi_pattern_registry_t;
typedef struct obi_automaton obi_automaton_t;

// Result codes
typedef enum {
    OBI_PROTOCOL_SUCCESS = 0,
    OBI_PROTOCOL_ERROR_INVALID_PATTERN,
    OBI_PROTOCOL_ERROR_VALIDATION_FAILED,
    OBI_PROTOCOL_ERROR_ZERO_TRUST_VIOLATION
} obi_protocol_result_t;

// Core API functions
obi_protocol_result_t obi_protocol_init(void);
void obi_protocol_cleanup(void);

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBIPROTOCOL_H */
