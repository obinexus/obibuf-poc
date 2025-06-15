#!/bin/bash
# OBINexus Layer Structure Creation Script
# Establishes proper three-layer architecture with corrected naming conventions

set -e

echo "🏗️ Creating OBINexus three-layer architecture..."

# Create directory structure for obitopology layer
echo "📁 Creating obitopology layer structure..."
mkdir -p obitopology/{src/core,src/utils,include,obj/core,obj/utils,tests/unit,tests/integration}

# Create obitopology header
cat > obitopology/include/obitopology.h << 'EOF'
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
EOF

# Create obitopology implementation
cat > obitopology/src/core/topology_core.c << 'EOF'
/*
 * OBI Topology Core Implementation
 * Network coordination and governance functionality
 */

#include "obitopology.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// Global topology state
static bool topology_initialized = false;
static obi_protocol_context_t *protocol_context = NULL;
static obi_topology_context_t topology_ctx = {0};

struct obi_topology_context {
    obi_topology_type_t network_type;
    obi_topology_metrics_t current_metrics;
    bool active;
};

obi_topology_result_t obi_topology_init(obi_protocol_context_t *protocol_ctx) {
    if (topology_initialized) {
        return OBI_TOPOLOGY_SUCCESS;
    }
    
    if (!protocol_ctx) {
        return OBI_TOPOLOGY_ERROR_PROTOCOL_DEPENDENCY;
    }
    
    // Initialize topology management
    protocol_context = protocol_ctx;
    topology_ctx.network_type = OBI_TOPOLOGY_P2P;
    topology_ctx.current_metrics.cost_function = 0.3;
    topology_ctx.current_metrics.active_nodes = 1;
    strcpy(topology_ctx.current_metrics.governance_zone, "AUTONOMOUS");
    topology_ctx.current_metrics.failover_enabled = true;
    topology_ctx.active = true;
    
    topology_initialized = true;
    return OBI_TOPOLOGY_SUCCESS;
}

void obi_topology_cleanup(void) {
    if (!topology_initialized) {
        return;
    }
    
    // Cleanup topology resources
    protocol_context = NULL;
    memset(&topology_ctx, 0, sizeof(topology_ctx));
    topology_initialized = false;
}

obi_topology_context_t* obi_topology_get_context(void) {
    return topology_initialized ? &topology_ctx : NULL;
}

obi_topology_result_t obi_topology_configure(obi_topology_context_t *ctx, obi_topology_type_t type) {
    if (!ctx || !topology_initialized) {
        return OBI_TOPOLOGY_ERROR_INVALID_CONFIG;
    }
    
    ctx->network_type = type;
    printf("Topology configured: %d\n", (int)type);
    
    return OBI_TOPOLOGY_SUCCESS;
}

obi_topology_result_t obi_topology_get_metrics(obi_topology_context_t *ctx, obi_topology_metrics_t *metrics) {
    if (!ctx || !metrics || !topology_initialized) {
        return OBI_TOPOLOGY_ERROR_INVALID_CONFIG;
    }
    
    *metrics = ctx->current_metrics;
    return OBI_TOPOLOGY_SUCCESS;
}

obi_result_t obi_topology_send_message(obi_topology_context_t *ctx, obi_buffer_t *buffer, const char *destination) {
    if (!ctx || !buffer || !destination || !topology_initialized) {
        return OBI_ERROR_INVALID_INPUT;
    }
    
    printf("Message sent via topology to: %s\n", destination);
    return OBI_SUCCESS;
}
EOF

# Create obitopology Makefile (corrected naming)
cat > obitopology/Makefile << 'EOF'
# OBIBUF Obitopology Layer Makefile
# OBINexus Computing - Aegis Framework

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC -DNASA_STD_8739_8
INCLUDES = -Iinclude -I../obiprotocol/include
SRCDIR = src
OBJDIR = obj
LIBDIR = ../dist/lib

# Source files
SOURCES = $(wildcard $(SRCDIR)/core/*.c $(SRCDIR)/utils/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Library names (OBINexus standard - NO lib prefix)
LIBNAME = obitopology.so
STATIC_LIBNAME = obitopology.a

# External dependencies (OBINexus standard linking)
PROTOCOL_LIB = $(LIBDIR)/obiprotocol.so

# Targets
all: $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

$(LIBDIR)/$(LIBNAME): $(OBJECTS) $(PROTOCOL_LIB) | $(LIBDIR)
	$(CC) -shared -o $@ $(OBJECTS) -L$(LIBDIR) -lobiprotocol

$(LIBDIR)/$(STATIC_LIBNAME): $(OBJECTS) | $(LIBDIR)
	ar rcs $@ $(OBJECTS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)/core $(OBJDIR)/utils

$(LIBDIR):
	mkdir -p $(LIBDIR)

clean:
	rm -rf $(OBJDIR)
	rm -f $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

.PHONY: all clean
EOF

echo "📁 Creating obibuffer layer structure..."
mkdir -p obibuffer/{src/core,src/utils,include,obj/core,obj/utils,tests/unit,tests/integration}

# Create obibuffer header
cat > obibuffer/include/obibuffer.h << 'EOF'
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
EOF

# Create obibuffer implementation
cat > obibuffer/src/core/buffer_core.c << 'EOF'
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
EOF

# Create obibuffer Makefile (corrected naming)
cat > obibuffer/Makefile << 'EOF'
# OBIBUF Obibuffer Layer Makefile
# OBINexus Computing - Aegis Framework

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC -DNASA_STD_8739_8
INCLUDES = -Iinclude -I../obitopology/include -I../obiprotocol/include
SRCDIR = src
OBJDIR = obj
LIBDIR = ../dist/lib

# Source files
SOURCES = $(wildcard $(SRCDIR)/core/*.c $(SRCDIR)/utils/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Library names (OBINexus standard - NO lib prefix)
LIBNAME = obibuffer.so
STATIC_LIBNAME = obibuffer.a

# External dependencies (OBINexus standard linking)
TOPOLOGY_LIB = $(LIBDIR)/obitopology.so
PROTOCOL_LIB = $(LIBDIR)/obiprotocol.so

# Targets
all: $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

$(LIBDIR)/$(LIBNAME): $(OBJECTS) $(TOPOLOGY_LIB) $(PROTOCOL_LIB) | $(LIBDIR)
	$(CC) -shared -o $@ $(OBJECTS) -L$(LIBDIR) -lobitopology -lobiprotocol

$(LIBDIR)/$(STATIC_LIBNAME): $(OBJECTS) | $(LIBDIR)
	ar rcs $@ $(OBJECTS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)/core $(OBJDIR)/utils

$(LIBDIR):
	mkdir -p $(LIBDIR)

clean:
	rm -rf $(OBJDIR)
	rm -f $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

.PHONY: all clean
EOF

# Create CLI source directory
echo "📁 Creating CLI source structure..."
mkdir -p cli

echo "✅ Layer structure creation completed with OBINexus standard naming!"
echo ""
echo "Next steps:"
echo "1. Execute: chmod +x create_layers.sh && ./create_layers.sh"
echo "2. Rebuild protocol layer: cd obiprotocol && make clean && make all"
echo "3. Build topology layer: cd obitopology && make clean && make all"
echo "4. Build buffer layer: cd obibuffer && make clean && make all"
echo "5. Build unified CLI: make cli"
echo ""
echo "Libraries will be generated as:"
echo "  - obiprotocol.so (NOT libobiprotocol.so)"
echo "  - obitopology.so (NOT libobitopology.so)"
echo "  - obibuffer.so (NOT libobibuffer.so)"
EOF
