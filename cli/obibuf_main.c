/*
 * OBIBuf Unified CLI - Main Interface
 * OBINexus Computing - Aegis Framework
 * 
 * Unified command-line interface for all three layers:
 * - obibuf protocol [commands]
 * - obibuf topology [commands] 
 * - obibuf buffer [commands]
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <unistd.h>

// Layer includes (hierarchical dependency)
#include "obiprotocol.h"
#include "obitopology.h" 
#include "obibuffer.h"

#define CLI_VERSION "1.0.0"
#define OBIBUF_SUCCESS 0
#define OBIBUF_ERROR 1

// Command categories
typedef enum {
    CMD_CATEGORY_PROTOCOL,
    CMD_CATEGORY_TOPOLOGY,
    CMD_CATEGORY_BUFFER,
    CMD_CATEGORY_HELP,
    CMD_CATEGORY_VERSION,
    CMD_CATEGORY_UNKNOWN
} command_category_t;

// Global CLI context for layer coordination
typedef struct {
    obi_protocol_context_t *protocol_ctx;
    obi_topology_context_t *topology_ctx;
    obi_buffer_context_t *buffer_ctx;
    bool verbose;
    bool zero_trust_mode;
    bool nasa_compliance;
    char *audit_log_path;
} obibuf_cli_context_t;

// Function prototypes
static void print_main_usage(const char *program_name);
static void print_version(void);
static command_category_t parse_category(const char *category);
static int initialize_layers(obibuf_cli_context_t *ctx);
static void cleanup_layers(obibuf_cli_context_t *ctx);
static int handle_protocol_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]);
static int handle_topology_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]);
static int handle_buffer_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]);

// Error handling with integration fallbacks
static void log_error(const char *layer, const char *operation, const char *error);
static void log_info(const char *layer, const char *message);

/*
 * Main Entry Point
 * Handles top-level command dispatching to appropriate layer handlers
 */
int main(int argc, char *argv[]) {
    obibuf_cli_context_t ctx = {0};
    
    // Require at least one argument (category)
    if (argc < 2) {
        print_main_usage(argv[0]);
        return OBIBUF_ERROR;
    }
    
    // Parse top-level category
    command_category_t category = parse_category(argv[1]);
    
    // Handle special cases first
    if (category == CMD_CATEGORY_VERSION) {
        print_version();
        return OBIBUF_SUCCESS;
    }
    
    if (category == CMD_CATEGORY_HELP) {
        print_main_usage(argv[0]);
        return OBIBUF_SUCCESS;
    }
    
    if (category == CMD_CATEGORY_UNKNOWN) {
        fprintf(stderr, "Error: Unknown command category '%s'\n", argv[1]);
        print_main_usage(argv[0]);
        return OBIBUF_ERROR;
    }
    
    // Initialize layer stack with error handling
    if (initialize_layers(&ctx) != OBIBUF_SUCCESS) {
        fprintf(stderr, "Error: Failed to initialize OBIBuf layer stack\n");
        return OBIBUF_ERROR;
    }
    
    int result = OBIBUF_ERROR;
    
    // Dispatch to appropriate layer handler
    switch (category) {
        case CMD_CATEGORY_PROTOCOL:
            result = handle_protocol_commands(&ctx, argc - 1, &argv[1]);
            break;
            
        case CMD_CATEGORY_TOPOLOGY:
            result = handle_topology_commands(&ctx, argc - 1, &argv[1]);
            break;
            
        case CMD_CATEGORY_BUFFER:
            result = handle_buffer_commands(&ctx, argc - 1, &argv[1]);
            break;
            
        default:
            fprintf(stderr, "Error: Unhandled command category\n");
            break;
    }
    
    // Cleanup layer stack
    cleanup_layers(&ctx);
    
    return result;
}

/*
 * Layer Initialization with Dependency Management
 * Enforces obiprotocol → obitopology → obibuffer hierarchy
 */
static int initialize_layers(obibuf_cli_context_t *ctx) {
    // Initialize protocol layer (foundation)
    ctx->protocol_ctx = obi_protocol_create_context(true); // Zero Trust mode
    if (!ctx->protocol_ctx) {
        log_error("PROTOCOL", "initialize", "Failed to create protocol context");
        return OBIBUF_ERROR;
    }
    
    // Initialize topology layer (depends on protocol)
    obi_topology_result_t topo_result = obi_topology_init(ctx->protocol_ctx);
    if (topo_result != OBI_TOPOLOGY_SUCCESS) {
        log_error("TOPOLOGY", "initialize", "Failed to initialize topology layer");
        obi_protocol_destroy_context(ctx->protocol_ctx);
        return OBIBUF_ERROR;
    }
    
    // Get topology context reference
    ctx->topology_ctx = obi_topology_get_context();
    
    // Initialize buffer layer (depends on topology)
    obi_buffer_result_t buffer_result = obi_buffer_init(ctx->topology_ctx);
    if (buffer_result != OBI_BUFFER_SUCCESS) {
        log_error("BUFFER", "initialize", "Failed to initialize buffer layer");
        obi_topology_cleanup();
        obi_protocol_destroy_context(ctx->protocol_ctx);
        return OBIBUF_ERROR;
    }
    
    // Get buffer context reference
    ctx->buffer_ctx = obi_buffer_get_context();
    
    log_info("SYSTEM", "All layers initialized successfully");
    return OBIBUF_SUCCESS;
}

/*
 * Protocol Layer Command Handler
 * Handles: validate, normalize, dfa, audit
 */
static int handle_protocol_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]) {
    if (argc < 2) {
        printf("Protocol layer commands:\n");
        printf("  obibuf protocol validate <file>     - Validate against DFA patterns\n");
        printf("  obibuf protocol normalize <input>   - Apply USCN normalization\n");
        printf("  obibuf protocol dfa <pattern>       - Test DFA pattern recognition\n");
        printf("  obibuf protocol audit <log>         - Generate compliance audit\n");
        return OBIBUF_ERROR;
    }
    
    const char *cmd = argv[1];
    
    if (strcmp(cmd, "validate") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Error: validate requires file argument\n");
            return OBIBUF_ERROR;
        }
        
        log_info("PROTOCOL", "Starting validation process");
        
        // Create validator with Zero Trust enforcement
        obi_validator_t *validator = obi_validator_create(ctx->protocol_ctx, true);
        if (!validator) {
            log_error("PROTOCOL", "validate", "Failed to create validator");
            return OBIBUF_ERROR;
        }
        
        // Load and validate file
        obi_buffer_t *buffer = obi_buffer_create_from_file(argv[2]);
        if (!buffer) {
            log_error("PROTOCOL", "validate", "Failed to load input file");
            obi_validator_destroy(validator);
            return OBIBUF_ERROR;
        }
        
        obi_result_t result = obi_validator_validate(validator, buffer);
        if (result == OBI_SUCCESS) {
            printf("✅ Validation: PASSED\n");
            printf("📊 DFA State: %s\n", obi_dfa_get_state_name(ctx->protocol_ctx));
        } else {
            printf("❌ Validation: FAILED (%s)\n", obi_result_to_string(result));
        }
        
        obi_buffer_destroy(buffer);
        obi_validator_destroy(validator);
        return (result == OBI_SUCCESS) ? OBIBUF_SUCCESS : OBIBUF_ERROR;
    }
    
    if (strcmp(cmd, "normalize") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Error: normalize requires input argument\n");
            return OBIBUF_ERROR;
        }
        
        log_info("PROTOCOL", "Applying USCN normalization");
        
        // Apply Unicode Security Considerations Normalization
        char normalized[8192];
        size_t normalized_len = sizeof(normalized);
        
        obi_result_t result = obi_uscn_normalize(argv[2], strlen(argv[2]), 
                                                normalized, &normalized_len);
        
        if (result == OBI_SUCCESS) {
            printf("Original:   %s\n", argv[2]);
            printf("Normalized: %s\n", normalized);
        } else {
            log_error("PROTOCOL", "normalize", obi_result_to_string(result));
            return OBIBUF_ERROR;
        }
        
        return OBIBUF_SUCCESS;
    }
    
    if (strcmp(cmd, "dfa") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Error: dfa requires pattern argument\n");
            return OBIBUF_ERROR;
        }
        
        log_info("PROTOCOL", "Testing DFA pattern recognition");
        
        // Test DFA pattern matching
        bool matches = obi_dfa_test_pattern(ctx->protocol_ctx, argv[2], strlen(argv[2]));
        printf("Pattern: %s\n", argv[2]);
        printf("DFA Match: %s\n", matches ? "YES" : "NO");
        printf("Current State: %s\n", obi_dfa_get_state_name(ctx->protocol_ctx));
        
        return OBIBUF_SUCCESS;
    }
    
    if (strcmp(cmd, "audit") == 0) {
        log_info("PROTOCOL", "Generating NASA-STD-8739.8 compliance audit");
        
        const char *audit_file = (argc >= 3) ? argv[2] : "protocol_audit.log";
        
        obi_result_t result = obi_generate_compliance_audit(ctx->protocol_ctx, audit_file);
        if (result == OBI_SUCCESS) {
            printf("✅ Compliance audit generated: %s\n", audit_file);
        } else {
            log_error("PROTOCOL", "audit", "Failed to generate audit");
            return OBIBUF_ERROR;
        }
        
        return OBIBUF_SUCCESS;
    }
    
    fprintf(stderr, "Error: Unknown protocol command '%s'\n", cmd);
    return OBIBUF_ERROR;
}

/*
 * Topology Layer Command Handler
 * Handles: network, governance, failover, metrics
 */
static int handle_topology_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]) {
    if (argc < 2) {
        printf("Topology layer commands:\n");
        printf("  obibuf topology network <type>      - Configure network topology\n");
        printf("  obibuf topology governance <zone>   - Set governance zone\n");
        printf("  obibuf topology failover <enable>   - Configure failover\n");
        printf("  obibuf topology metrics             - Show network metrics\n");
        return OBIBUF_ERROR;
    }
    
    const char *cmd = argv[1];
    
    if (strcmp(cmd, "network") == 0) {
        if (argc < 3) {
            fprintf(stderr, "Error: network requires topology type\n");
            fprintf(stderr, "Types: p2p, bus, ring, star, mesh, hybrid\n");
            return OBIBUF_ERROR;
        }
        
        log_info("TOPOLOGY", "Configuring network topology");
        
        obi_topology_type_t type;
        if (strcmp(argv[2], "p2p") == 0) type = OBI_TOPOLOGY_P2P;
        else if (strcmp(argv[2], "mesh") == 0) type = OBI_TOPOLOGY_MESH;
        else if (strcmp(argv[2], "star") == 0) type = OBI_TOPOLOGY_STAR;
        else {
            fprintf(stderr, "Error: Unknown topology type '%s'\n", argv[2]);
            return OBIBUF_ERROR;
        }
        
        obi_topology_result_t result = obi_topology_configure(ctx->topology_ctx, type);
        if (result == OBI_TOPOLOGY_SUCCESS) {
            printf("✅ Network topology configured: %s\n", argv[2]);
        } else {
            log_error("TOPOLOGY", "network", "Configuration failed");
            return OBIBUF_ERROR;
        }
        
        return OBIBUF_SUCCESS;
    }
    
    if (strcmp(cmd, "metrics") == 0) {
        log_info("TOPOLOGY", "Retrieving network metrics");
        
        obi_topology_metrics_t metrics;
        obi_topology_result_t result = obi_topology_get_metrics(ctx->topology_ctx, &metrics);
        
        if (result == OBI_TOPOLOGY_SUCCESS) {
            printf("📊 Network Metrics:\n");
            printf("   Cost Function: %.3f (threshold: 0.5)\n", metrics.cost_function);
            printf("   Active Nodes: %d\n", metrics.active_nodes);
            printf("   Governance Zone: %s\n", metrics.governance_zone);
            printf("   Failover Status: %s\n", metrics.failover_enabled ? "ENABLED" : "DISABLED");
        } else {
            log_error("TOPOLOGY", "metrics", "Failed to retrieve metrics");
            return OBIBUF_ERROR;
        }
        
        return OBIBUF_SUCCESS;
    }
    
    fprintf(stderr, "Error: Unknown topology command '%s'\n", cmd);
    return OBIBUF_ERROR;
}

/*
 * Buffer Layer Command Handler  
 * Handles: send, receive, validate, audit
 */
static int handle_buffer_commands(obibuf_cli_context_t *ctx, int argc, char *argv[]) {
    if (argc < 2) {
        printf("Buffer layer commands:\n");
        printf("  obibuf buffer send <msg> <dest>     - Send message via topology\n");
        printf("  obibuf buffer receive <timeout>     - Receive messages\n");
        printf("  obibuf buffer validate <buffer>     - Validate buffer contents\n");
        printf("  obibuf buffer audit                 - Generate audit trail\n");
        return OBIBUF_ERROR;
    }
    
    const char *cmd = argv[1];
    
    if (strcmp(cmd, "send") == 0) {
        if (argc < 4) {
            fprintf(stderr, "Error: send requires message and destination\n");
            return OBIBUF_ERROR;
        }
        
        log_info("BUFFER", "Sending message via topology layer");
        
        // Create message buffer with protocol validation
        obi_buffer_t *msg_buffer = obi_buffer_create(8192);
        if (!msg_buffer) {
            log_error("BUFFER", "send", "Failed to create message buffer");
            return OBIBUF_ERROR;
        }
        
        // Set message data
        obi_result_t result = obi_buffer_set_data(msg_buffer, 
                                                 (uint8_t*)argv[2], strlen(argv[2]));
        if (result != OBI_SUCCESS) {
            log_error("BUFFER", "send", "Failed to set message data");
            obi_buffer_destroy(msg_buffer);
            return OBIBUF_ERROR;
        }
        
        // Send via topology layer with Zero Trust enforcement
        result = obi_topology_send_message(ctx->topology_ctx, msg_buffer, argv[3]);
        if (result == OBI_SUCCESS) {
            printf("✅ Message sent to %s\n", argv[3]);
        } else {
            log_error("BUFFER", "send", "Failed to send message");
            obi_buffer_destroy(msg_buffer);
            return OBIBUF_ERROR;
        }
        
        obi_buffer_destroy(msg_buffer);
        return OBIBUF_SUCCESS;
    }
    
    if (strcmp(cmd, "audit") == 0) {
        log_info("BUFFER", "Generating comprehensive audit trail");
        
        const char *audit_file = (argc >= 3) ? argv[2] : "buffer_audit.log";
        
        obi_buffer_result_t result = obi_buffer_generate_audit(ctx->buffer_ctx, audit_file);
        if (result == OBI_BUFFER_SUCCESS) {
            printf("✅ Buffer audit trail generated: %s\n", audit_file);
        } else {
            log_error("BUFFER", "audit", "Failed to generate audit");
            return OBIBUF_ERROR;
        }
        
        return OBIBUF_SUCCESS;
    }
    
    fprintf(stderr, "Error: Unknown buffer command '%s'\n", cmd);
    return OBIBUF_ERROR;
}

/*
 * Utility Functions
 */
static command_category_t parse_category(const char *category) {
    if (strcmp(category, "protocol") == 0) return CMD_CATEGORY_PROTOCOL;
    if (strcmp(category, "topology") == 0) return CMD_CATEGORY_TOPOLOGY;
    if (strcmp(category, "buffer") == 0) return CMD_CATEGORY_BUFFER;
    if (strcmp(category, "help") == 0 || strcmp(category, "--help") == 0) return CMD_CATEGORY_HELP;
    if (strcmp(category, "version") == 0 || strcmp(category, "--version") == 0) return CMD_CATEGORY_VERSION;
    return CMD_CATEGORY_UNKNOWN;
}

static void print_main_usage(const char *program_name) {
    printf("OBIBuf Unified CLI v%s\n", CLI_VERSION);
    printf("OBINexus Computing - Aegis Framework\n\n");
    printf("Usage: %s <category> [commands...]\n\n", program_name);
    printf("Categories:\n");
    printf("  protocol     Protocol layer operations (DFA, validation, normalization)\n");
    printf("  topology     Topology layer operations (network, governance, metrics)\n");
    printf("  buffer       Buffer layer operations (send, receive, audit)\n");
    printf("  version      Show version information\n");
    printf("  help         Show this help message\n\n");
    printf("Examples:\n");
    printf("  %s protocol validate input.bin\n", program_name);
    printf("  %s topology network p2p\n", program_name);
    printf("  %s buffer send \"Hello\" node1\n", program_name);
    printf("\nFor category-specific help: %s <category>\n", program_name);
}

static void print_version(void) {
    printf("OBIBuf CLI v%s\n", CLI_VERSION);
    printf("OBINexus Computing - Aegis Framework\n");
    printf("Build: Protocol+Topology+Buffer layers\n");
    printf("Compliance: NASA-STD-8739.8, Zero Trust Architecture\n");
}

static void cleanup_layers(obibuf_cli_context_t *ctx) {
    if (ctx->buffer_ctx) {
        obi_buffer_cleanup();
    }
    if (ctx->topology_ctx) {
        obi_topology_cleanup();
    }
    if (ctx->protocol_ctx) {
        obi_protocol_destroy_context(ctx->protocol_ctx);
    }
}

static void log_error(const char *layer, const char *operation, const char *error) {
    fprintf(stderr, "[%s ERROR] %s: %s\n", layer, operation, error);
}

static void log_info(const char *layer, const char *message) {
    printf("[%s] %s\n", layer, message);
}
