/*
 * OBI Buffer Core Implementation
 * CLI interface and validation framework
 */

#include "obibuffer.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Global buffer state
static bool buffer_initialized = false;
static obi_topology_context_t *topology_context = NULL;
static obi_buffer_context_t buffer_ctx = {0};

struct obi_buffer_context {
    bool audit_enabled;
    char audit_path[256];
    bool active;
};

obi_buffer_result_t obi_buffer_init(obi_topology_context_t *topology_ctx) {
    if (buffer_initialized) {
        return OBI_BUFFER_SUCCESS;
    }
    
    if (!topology_ctx) {
        return OBI_BUFFER_ERROR_TOPOLOGY_DEPENDENCY;
    }
    
    // Initialize buffer management
    topology_context = topology_ctx;
    buffer_ctx.audit_enabled = true;
    strcpy(buffer_ctx.audit_path, "audit.log");
    buffer_ctx.active = true;
    
    buffer_initialized = true;
    return OBI_BUFFER_SUCCESS;
}

void obi_buffer_cleanup(void) {
    if (!buffer_initialized) {
        return;
    }
    
    // Cleanup buffer resources
    topology_context = NULL;
    memset(&buffer_ctx, 0, sizeof(buffer_ctx));
    buffer_initialized = false;
}

obi_buffer_context_t* obi_buffer_get_context(void) {
    return buffer_initialized ? &buffer_ctx : NULL;
}

obi_buffer_result_t obi_buffer_generate_audit(obi_buffer_context_t *ctx, const char *filename) {
    if (!ctx || !filename || !buffer_initialized) {
        return OBI_BUFFER_ERROR_VALIDATION_FAILED;
    }
    
    FILE *audit_file = fopen(filename, "w");
    if (!audit_file) {
        return OBI_BUFFER_ERROR_VALIDATION_FAILED;
    }
    
    fprintf(audit_file, "OBI Buffer Audit Report\n");
    fprintf(audit_file, "======================\n");
    fprintf(audit_file, "Status: Active\n");
    fprintf(audit_file, "Audit Enabled: %s\n", ctx->audit_enabled ? "YES" : "NO");
    
    fclose(audit_file);
    printf("Audit report generated: %s\n", filename);
    
    return OBI_BUFFER_SUCCESS;
}
