/*
 * OBI Protocol DFA Engine Header - Complete Implementation
 * Language-Agnostic Parser with USCN Integration
 * Part of OBIBUF Protocol Stack
 */

#ifndef OBIPROTOCOL_DFA_H
#define OBIPROTOCOL_DFA_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <regex.h>

// Protocol DFA Configuration Constants
#define OBI_MAX_STATES 256
#define OBI_MAX_TRANSITIONS 1024
#define OBI_MAX_PATTERN_LENGTH 512
#define OBI_CANONICAL_BUFFER_SIZE 8192

// Semantic Pattern Types (Language-Agnostic)
typedef enum {
    PATTERN_PROTOCOL_HEADER = 0,    // Message protocol identification
    PATTERN_SECURITY_TOKEN,         // Cryptographic authentication tokens
    PATTERN_DATA_PAYLOAD,           // Binary/text payload data
    PATTERN_SCHEMA_REFERENCE,       // Schema validation identifiers
    PATTERN_AUDIT_MARKER,           // NASA-STD-8739.8 audit requirements
    PATTERN_TRANSITION_BOUNDARY,    // State transition checkpoints
    PATTERN_CANONICAL_DELIMITER,    // USCN structural separators
    PATTERN_ERROR_RECOVERY,         // Graceful degradation markers
    PATTERN_MAX_TYPES
} obi_semantic_pattern_t;

// Forward declaration for transition structure
struct obi_transition;

// DFA State Definition
typedef struct {
    uint32_t state_id;
    obi_semantic_pattern_t pattern_type;
    char regex_pattern[OBI_MAX_PATTERN_LENGTH];
    bool is_accepting;
    bool requires_zero_trust_validation;
    uint32_t transition_count;
    struct obi_transition *transitions;
} obi_dfa_state_t;

// State Transition Definition
typedef struct obi_transition {
    uint32_t from_state;
    uint32_t to_state;
    char input_symbol;
    bool (*validation_function)(const char *input, size_t length);
    double cost_weight;  // For Sinphasé governance monitoring
} obi_transition_t;

// USCN Normalization Context
typedef struct {
    bool case_sensitive;
    bool whitespace_normalize;
    bool encoding_normalize;
    char canonical_buffer[OBI_CANONICAL_BUFFER_SIZE];
    size_t buffer_used;
} obi_uscn_context_t;

// Language-Agnostic DFA Engine - Complete Structure
typedef struct obi_protocol_dfa {
    obi_dfa_state_t states[OBI_MAX_STATES];
    obi_transition_t transitions[OBI_MAX_TRANSITIONS];
    uint32_t state_count;
    uint32_t transition_count;
    uint32_t current_state;
    obi_uscn_context_t uscn_context;
    bool zero_trust_enforced;
    double governance_cost_accumulator;
} obi_protocol_dfa_t;

// Canonical IR Node Types
typedef enum {
    IR_PROTOCOL_MESSAGE,
    IR_SECURITY_CONTEXT,
    IR_PAYLOAD_BLOCK,
    IR_SCHEMA_VALIDATION,
    IR_AUDIT_RECORD,
    IR_ERROR_CONDITION
} obi_ir_node_type_t;

// Complete IR Node Structure
typedef struct obi_ir_node {
    obi_ir_node_type_t type;
    char *canonical_content;
    size_t content_length;
    uint32_t source_state;
    double governance_cost;
    struct obi_ir_node *next;
} obi_ir_node_t;

// API Functions

/**
 * Initialize DFA engine with Zero Trust enforcement
 */
int obi_dfa_initialize(obi_protocol_dfa_t *dfa, bool zero_trust_mode);

/**
 * Register semantic pattern with regex and validation
 */
int obi_dfa_register_pattern(obi_protocol_dfa_t *dfa, 
                            obi_semantic_pattern_t pattern_type,
                            const char *regex_pattern,
                            bool (*validator)(const char *, size_t));

/**
 * USCN normalization function - eliminates encoding variations
 */
int obi_uscn_normalize(obi_uscn_context_t *ctx, 
                      const char *input, 
                      size_t input_len,
                      char *canonical_output,
                      size_t *output_len);

/**
 * Process input through DFA with canonical validation
 */
int obi_dfa_process_input(obi_protocol_dfa_t *dfa,
                         const char *input,
                         size_t input_length,
                         obi_ir_node_t **ir_output);

/**
 * Validate canonical equivalence (Zero Trust requirement)
 */
bool obi_validate_canonical_equivalence(const char *input1, 
                                       const char *input2,
                                       obi_uscn_context_t *ctx);

/**
 * Generate cross-language serializable DFA specification
 */
int obi_dfa_export_specification(obi_protocol_dfa_t *dfa,
                                const char *output_format, // "yaml", "json", "c_header"
                                char *output_buffer,
                                size_t buffer_size);

/**
 * Sinphasé governance cost monitoring
 */
double obi_calculate_governance_cost(obi_protocol_dfa_t *dfa);

// Predefined Semantic Patterns (Cross-Language Compatible)
extern const char* OBI_PATTERN_HEADER_MARKER;      // "^OBI-PROTOCOL-[0-9]+\\.[0-9]+:"
extern const char* OBI_PATTERN_SECURITY_TOKEN;     // "SEC:[A-F0-9]{64}"
extern const char* OBI_PATTERN_PAYLOAD_DELIMITER;  // "PAYLOAD\\|[0-9]+\\|"
extern const char* OBI_PATTERN_SCHEMA_REF;         // "SCHEMA:[A-Za-z0-9_-]+\\.[0-9]+"
extern const char* OBI_PATTERN_AUDIT_TIMESTAMP;    // "AUDIT:[0-9]{13}"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* OBIPROTOCOL_DFA_H */