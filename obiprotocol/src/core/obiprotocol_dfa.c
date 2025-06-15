/*
 * OBI Protocol DFA Implementation
 * Zero Trust Language-Agnostic Protocol Parsing
 * Integrates USCN normalization with governance monitoring
 */

#include "obiprotocol_dfa.h"
#include <string.h>
#include <stdlib.h>
#include <regex.h>
#include <math.h>

// Predefined Cross-Language Semantic Patterns
const char* OBI_PATTERN_HEADER_MARKER = "^OBI-PROTOCOL-[0-9]+\\.[0-9]+:";
const char* OBI_PATTERN_SECURITY_TOKEN = "SEC:[A-F0-9]{64}";
const char* OBI_PATTERN_PAYLOAD_DELIMITER = "PAYLOAD\\|[0-9]+\\|";
const char* OBI_PATTERN_SCHEMA_REF = "SCHEMA:[A-Za-z0-9_-]+\\.[0-9]+";
const char* OBI_PATTERN_AUDIT_TIMESTAMP = "AUDIT:[0-9]{13}";

// USCN Character Encoding Mappings (Prevent Exploit Vectors)
typedef struct {
    const char *encoded_form;
    const char *canonical_form;
    size_t encoded_len;
    size_t canonical_len;
} uscn_mapping_t;

static const uscn_mapping_t uscn_encoding_map[] = {
    // Path traversal normalization
    {"%2e%2e%2f", "../", 9, 3},
    {"%c0%af", "../", 6, 3},
    {".%2e/", "../", 5, 3},
    {"%2e%2e/", "../", 7, 3},
    
    // Character normalization  
    {"%2f", "/", 3, 1},
    {"%2e", ".", 3, 1},
    {"%20", " ", 3, 1},
    
    // Unicode overlong encodings
    {"%c0%ae", ".", 6, 1},
    {"%c0%af", "/", 6, 1},
    
    // Protocol delimiters
    {"%3A", ":", 3, 1},
    {"%7C", "|", 3, 1},
    
    // End marker
    {NULL, NULL, 0, 0}
};

/**
 * Create IR node from DFA state transition
 */
static obi_ir_node_t* create_ir_node(uint32_t source_state, 
                                     obi_semantic_pattern_t pattern_type,
                                     const char *canonical_content,
                                     size_t content_length,
                                     double governance_cost) {
    obi_ir_node_t *node = malloc(sizeof(obi_ir_node_t));
    if (!node) return NULL;
    
    // Map semantic pattern to IR node type
    switch (pattern_type) {
        case PATTERN_PROTOCOL_HEADER:
            node->type = IR_PROTOCOL_MESSAGE;
            break;
        case PATTERN_SECURITY_TOKEN:
            node->type = IR_SECURITY_CONTEXT;
            break;
        case PATTERN_DATA_PAYLOAD:
            node->type = IR_PAYLOAD_BLOCK;
            break;
        case PATTERN_SCHEMA_REFERENCE:
            node->type = IR_SCHEMA_VALIDATION;
            break;
        case PATTERN_AUDIT_MARKER:
            node->type = IR_AUDIT_RECORD;
            break;
        default:
            node->type = IR_ERROR_CONDITION;
            break;
    }
    
    node->canonical_content = malloc(content_length + 1);
    if (node->canonical_content) {
        memcpy(node->canonical_content, canonical_content, content_length);
        node->canonical_content[content_length] = '\0';
    }
    
    node->content_length = content_length;
    node->source_state = source_state;
    node->governance_cost = governance_cost;
    node->next = NULL;
    
    return node;
}

/**
 * Initialize DFA engine with Zero Trust enforcement
 */
int obi_dfa_initialize(obi_protocol_dfa_t *dfa, bool zero_trust_mode) {
    if (!dfa) return -1;
    
    // Clear DFA structure
    memset(dfa, 0, sizeof(obi_protocol_dfa_t));
    
    // Configure Zero Trust enforcement
    dfa->zero_trust_enforced = zero_trust_mode;
    dfa->current_state = 0;
    dfa->governance_cost_accumulator = 0.0;
    
    // Initialize USCN context
    dfa->uscn_context.case_sensitive = false;
    dfa->uscn_context.whitespace_normalize = true;
    dfa->uscn_context.encoding_normalize = true;
    dfa->uscn_context.buffer_used = 0;
    
    // Create initial state (protocol start)
    dfa->states[0].state_id = 0;
    dfa->states[0].pattern_type = PATTERN_PROTOCOL_HEADER;
    strncpy(dfa->states[0].regex_pattern, OBI_PATTERN_HEADER_MARKER, OBI_MAX_PATTERN_LENGTH - 1);
    dfa->states[0].regex_pattern[OBI_MAX_PATTERN_LENGTH - 1] = '\0';
    dfa->states[0].is_accepting = false;
    dfa->states[0].requires_zero_trust_validation = true;
    dfa->state_count = 1;
    
    return 0;
}

/**
 * USCN normalization - eliminates encoding variations
 */
int obi_uscn_normalize(obi_uscn_context_t *ctx, 
                      const char *input, 
                      size_t input_len,
                      char *canonical_output,
                      size_t *output_len) {
    if (!ctx || !input || !canonical_output || !output_len) return -1;
    
    size_t input_pos = 0;
    size_t output_pos = 0;
    size_t max_output = *output_len;
    
    // Phase 1: Apply character encoding mappings
    while (input_pos < input_len && output_pos < max_output - 1) {
        bool mapped = false;
        
        // Check for multi-character encoding mappings
        for (const uscn_mapping_t *mapping = uscn_encoding_map; 
             mapping->encoded_form != NULL; mapping++) {
            
            if (input_pos + mapping->encoded_len <= input_len &&
                memcmp(input + input_pos, mapping->encoded_form, 
                       mapping->encoded_len) == 0) {
                
                // Apply canonical mapping
                if (output_pos + mapping->canonical_len < max_output) {
                    memcpy(canonical_output + output_pos, mapping->canonical_form, 
                           mapping->canonical_len);
                    output_pos += mapping->canonical_len;
                    input_pos += mapping->encoded_len;
                    mapped = true;
                    break;
                }
            }
        }
        
        // If no mapping found, copy character directly
        if (!mapped) {
            canonical_output[output_pos++] = input[input_pos++];
        }
    }
    
    // Phase 2: Case normalization (if enabled)
    if (!ctx->case_sensitive) {
        for (size_t i = 0; i < output_pos; i++) {
            if (canonical_output[i] >= 'A' && canonical_output[i] <= 'Z') {
                canonical_output[i] += 32; // Convert to lowercase
            }
        }
    }
    
    // Phase 3: Whitespace normalization
    if (ctx->whitespace_normalize) {
        size_t write_pos = 0;
        bool in_whitespace = false;
        
        for (size_t i = 0; i < output_pos; i++) {
            if (canonical_output[i] == ' ' || canonical_output[i] == '\t' || 
                canonical_output[i] == '\n' || canonical_output[i] == '\r') {
                if (!in_whitespace) {
                    canonical_output[write_pos++] = ' ';
                    in_whitespace = true;
                }
            } else {
                canonical_output[write_pos++] = canonical_output[i];
                in_whitespace = false;
            }
        }
        output_pos = write_pos;
    }
    
    canonical_output[output_pos] = '\0';
    *output_len = output_pos;
    
    // Store in context for governance tracking
    if (output_pos < OBI_CANONICAL_BUFFER_SIZE) {
        memcpy(ctx->canonical_buffer, canonical_output, output_pos);
        ctx->buffer_used = output_pos;
    }
    
    return 0;
}

/**
 * Validate canonical equivalence (Zero Trust requirement)
 */
bool obi_validate_canonical_equivalence(const char *input1, 
                                       const char *input2,
                                       obi_uscn_context_t *ctx) {
    if (!input1 || !input2 || !ctx) return false;
    
    char canonical1[OBI_CANONICAL_BUFFER_SIZE];
    char canonical2[OBI_CANONICAL_BUFFER_SIZE];
    size_t len1 = OBI_CANONICAL_BUFFER_SIZE;
    size_t len2 = OBI_CANONICAL_BUFFER_SIZE;
    
    // Normalize both inputs
    if (obi_uscn_normalize(ctx, input1, strlen(input1), canonical1, &len1) != 0 ||
        obi_uscn_normalize(ctx, input2, strlen(input2), canonical2, &len2) != 0) {
        return false;
    }
    
    // Compare canonical forms
    return (len1 == len2) && (memcmp(canonical1, canonical2, len1) == 0);
}

/**
 * Register semantic pattern with validation
 */
int obi_dfa_register_pattern(obi_protocol_dfa_t *dfa, 
                            obi_semantic_pattern_t pattern_type,
                            const char *regex_pattern,
                            bool (*)(const char *, size_t)) {
    if (!dfa || !regex_pattern || dfa->state_count >= OBI_MAX_STATES) return -1;
    
    uint32_t state_id = dfa->state_count;
    obi_dfa_state_t *state = &dfa->states[state_id];
    
    state->state_id = state_id;
    state->pattern_type = pattern_type;
    strncpy(state->regex_pattern, regex_pattern, OBI_MAX_PATTERN_LENGTH - 1);
    state->regex_pattern[OBI_MAX_PATTERN_LENGTH - 1] = '\0';
    state->is_accepting = (pattern_type == PATTERN_DATA_PAYLOAD || 
                          pattern_type == PATTERN_AUDIT_MARKER);
    state->requires_zero_trust_validation = dfa->zero_trust_enforced;
    state->transition_count = 0;
    
    dfa->state_count++;
    
    return state_id;
}

/**
 * Process input through DFA with canonical validation
 */
int obi_dfa_process_input(obi_protocol_dfa_t *dfa,
                         const char *input,
                         size_t input_length,
                         obi_ir_node_t **ir_output) {
    if (!dfa || !input || !ir_output) return -1;
    
    // Phase 1: USCN normalization (Zero Trust requirement)
    char canonical_input[OBI_CANONICAL_BUFFER_SIZE];
    size_t canonical_length = OBI_CANONICAL_BUFFER_SIZE;
    
    if (obi_uscn_normalize(&dfa->uscn_context, input, input_length, 
                          canonical_input, &canonical_length) != 0) {
        return -1;
    }
    
    // Phase 2: DFA state traversal
    obi_ir_node_t *ir_head = NULL;
    obi_ir_node_t *ir_current = NULL;
    uint32_t current_state = 0;
    size_t pos = 0;
    
    while (pos < canonical_length) {
        bool state_matched = false;
        
        // Check all states for pattern matches
        for (uint32_t i = 0; i < dfa->state_count; i++) {
            obi_dfa_state_t *state = &dfa->states[i];
            
            // Compile and test regex pattern
            regex_t regex;
            if (regcomp(&regex, state->regex_pattern, REG_EXTENDED) == 0) {
                regmatch_t match;
                
                if (regexec(&regex, canonical_input + pos, 1, &match, 0) == 0 &&
                    match.rm_so == 0) {
                    
                    // Pattern matched - create IR node
                    size_t match_length = match.rm_eo - match.rm_so;
                    double cost = 0.1 * match_length; // Simple cost model
                    
                    obi_ir_node_t *node = create_ir_node(
                        current_state, 
                        state->pattern_type,
                        canonical_input + pos,
                        match_length,
                        cost
                    );
                    
                    if (node) {
                        if (!ir_head) {
                            ir_head = ir_current = node;
                        } else {
                            ir_current->next = node;
                            ir_current = node;
                        }
                    }
                    
                    pos += match_length;
                    current_state = state->state_id;
                    dfa->governance_cost_accumulator += cost;
                    state_matched = true;
                    break;
                }
                
                regfree(&regex);
            }
        }
        
        if (!state_matched) {
            pos++; // Skip unrecognized character
        }
    }
    
    *ir_output = ir_head;
    dfa->current_state = current_state;
    
    return 0;
}

/**
 * Calculate Sinphasé governance cost
 */
double obi_calculate_governance_cost(obi_protocol_dfa_t *dfa) {
    if (!dfa) return -1.0;
    
    double cost = dfa->governance_cost_accumulator;
    
    // Add complexity penalties
    cost += 0.01 * dfa->state_count;        // State complexity
    cost += 0.005 * dfa->transition_count;  // Transition complexity
    
    // Zero Trust overhead
    if (dfa->zero_trust_enforced) {
        cost += 0.05; // Fixed ZT overhead
    }
    
    return cost;
}

/**
 * Generate cross-language serializable DFA specification (placeholder)
 */
int obi_dfa_export_specification(obi_protocol_dfa_t *dfa,
                                const char *output_format,
                                char *output_buffer,
                                size_t buffer_size) {
    // TODO: Implement full specification export
    (void)dfa;
    (void)output_format;
    (void)output_buffer;
    (void)buffer_size;
    return 0;
}