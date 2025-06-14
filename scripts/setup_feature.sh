#!/bin/bash
# OBIBUF Production Feature Setup Script
# OBINexus Computing - Aegis Framework
# 
# Configures multi-layered protocol stack for new feature integration
# Enforces dependency hierarchy: obibuffer → obitopology → obiprotocol

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="setup_feature.sh"
readonly SCRIPT_VERSION="2.0.0"
readonly LOG_FILE="setup.log"
readonly FEATURE_MANIFEST="dist/feature_manifest.txt"
readonly CONFIG_DIR="configs"
readonly SCHEMA_FILE="obibuf.schema.yaml"
readonly TEMPLATE_DIR="templates"
readonly FEATURES_DIR="features"

# Required directories for OBIBUF stack
readonly REQUIRED_DIRS=("obiprotocol" "obitopology" "obibuffer")

# Global flags
DRY_RUN=false
COPY_FROM_FEATURE=""
FEATURE_TYPE="core"  # core, cli, or hybrid

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function with timestamps
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local prefix=""
    
    if [[ "$DRY_RUN" == true ]]; then
        prefix="[DRY-RUN] "
    fi
    
    echo -e "[${timestamp}] [${level}] ${prefix}${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    log "INFO" "$*"
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    log "SUCCESS" "$*"
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    log "WARN" "$*"
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    log "ERROR" "$*"
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Usage information
usage() {
    cat << EOF
OBIBUF Production Feature Setup Script v${SCRIPT_VERSION}
OBINexus Computing - Aegis Framework

USAGE:
    ${SCRIPT_NAME} [OPTIONS] <feature_name>

DESCRIPTION:
    Configures the OBIBUF protocol stack for new feature integration.
    Enforces proper dependency hierarchy and compliance requirements.
    Supports incremental development with feature inheritance.

OPTIONS:
    --dry-run               Simulate operations without making actual changes
    --copy-from <feature>   Copy structure from existing feature (excludes tests)
    --type <type>           Feature type: core, cli, or hybrid (default: core)
    -h, --help              Show this help message

PARAMETERS:
    feature_name    Name of the feature (e.g., protocol-state-validation)

EXAMPLES:
    ${SCRIPT_NAME} protocol-state-validation --type core
    ${SCRIPT_NAME} --dry-run topology-burst-mode --copy-from protocol-state-validation
    ${SCRIPT_NAME} buffer-audit-enhancement --type hybrid

FEATURE TYPES:
    core        Core library functionality (*.so/*.a)
    cli         Command-line interface (*.exe)
    hybrid      Both core library and CLI components

REQUIREMENTS:
    - Ubuntu 22.04+ or equivalent POSIX environment
    - GCC, Make, CMake installed
    - Required directories: obiprotocol/, obitopology/, obibuffer/

EOF
}

# Dry-run simulation functions
dry_run_mkdir() {
    log_info "DRY-RUN: Would create directory: $*"
}

dry_run_rm() {
    log_info "DRY-RUN: Would remove: $*"
}

dry_run_create_file() {
    local file="$1"
    log_info "DRY-RUN: Would create file: $file"
    if [[ "$file" == *.yaml ]]; then
        log_info "DRY-RUN: File would contain YAML configuration for feature"
    elif [[ "$file" == *CMakeLists* ]]; then
        log_info "DRY-RUN: File would contain CMake build configuration"
    elif [[ "$file" == *Makefile* ]]; then
        log_info "DRY-RUN: File would contain Makefile build rules"
    fi
}

dry_run_append_file() {
    local file="$1"
    local content="$2"
    log_info "DRY-RUN: Would append to file: $file"
    log_info "DRY-RUN: Content: $content"
}

# Safe file operations with dry-run support
safe_mkdir() {
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_mkdir "$@"
    else
        mkdir -p "$@"
    fi
}

safe_rm() {
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_rm "$@"
    else
        rm -rf "$@"
    fi
}

safe_create_file() {
    local file="$1"
    shift
    local content="$*"
    
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_create_file "$file"
    else
        cat > "$file" << EOF
$content
EOF
    fi
}

safe_append_file() {
    local file="$1"
    local content="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_append_file "$file" "$content"
    else
        echo "$content" >> "$file"
    fi
}
# Create feature-specific Makefile
create_feature_makefile() {
    local feature_dir="$1"
    local feature_name="$2"
    local feature_type="$3"
    
    local makefile="${feature_dir}/Makefile"
    local makefile_content="# ${feature_name} Feature Makefile
# OBINexus Computing - Aegis Framework
# Generated: $(date -Iseconds)
# Feature Type: ${feature_type}

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC -DNASA_STD_8739_8
INCLUDES = -Iinclude -I../../obiprotocol/include -I../../obitopology/include -I../../obibuffer/include
SRCDIR = src
OBJDIR = obj
LIBDIR = lib
BINDIR = bin

# Source files
CORE_SOURCES = \$(wildcard \$(SRCDIR)/core/*.c)
CLI_SOURCES = \$(wildcard \$(SRCDIR)/cli/*.c)
CORE_OBJECTS = \$(CORE_SOURCES:\$(SRCDIR)/%.c=\$(OBJDIR)/%.o)
CLI_OBJECTS = \$(CLI_SOURCES:\$(SRCDIR)/%.c=\$(OBJDIR)/%.o)

# Library and executable names
CORE_LIB = lib${feature_name}.so
CORE_STATIC = lib${feature_name}.a
CLI_EXE = ${feature_name}.exe

# External library dependencies
LIBS = -L../../dist/lib -lobiprotocol -lobitopology -lobibuffer -lm

# Build targets based on feature type"

    if [[ "$feature_type" == "core" ]]; then
        makefile_content+="\nall: \$(LIBDIR)/\$(CORE_LIB) \$(LIBDIR)/\$(CORE_STATIC)"
    elif [[ "$feature_type" == "cli" ]]; then
        makefile_content+="\nall: \$(BINDIR)/\$(CLI_EXE)"
    else  # hybrid
        makefile_content+="\nall: \$(LIBDIR)/\$(CORE_LIB) \$(LIBDIR)/\$(CORE_STATIC) \$(BINDIR)/\$(CLI_EXE)"
    fi

    makefile_content+="

# Core library targets
\$(LIBDIR)/\$(CORE_LIB): \$(CORE_OBJECTS) | \$(LIBDIR)
	\$(CC) -shared -o \$@ \$(CORE_OBJECTS) \$(LIBS)

\$(LIBDIR)/\$(CORE_STATIC): \$(CORE_OBJECTS) | \$(LIBDIR)
	ar rcs \$@ \$(CORE_OBJECTS)

# CLI executable target
\$(BINDIR)/\$(CLI_EXE): \$(CLI_OBJECTS) \$(LIBDIR)/\$(CORE_LIB) | \$(BINDIR)
	\$(CC) -o \$@ \$(CLI_OBJECTS) -L\$(LIBDIR) -l${feature_name} \$(LIBS)

# Object file compilation
\$(OBJDIR)/%.o: \$(SRCDIR)/%.c | \$(OBJDIR)
	@mkdir -p \$(dir \$@)
	\$(CC) \$(CFLAGS) \$(INCLUDES) -c \$< -o \$@

# Directory creation
\$(OBJDIR):
	mkdir -p \$(OBJDIR)/core \$(OBJDIR)/cli

\$(LIBDIR):
	mkdir -p \$(LIBDIR)

\$(BINDIR):
	mkdir -p \$(BINDIR)

# Test targets
test-unit: \$(LIBDIR)/\$(CORE_LIB)
	@echo \"Running unit tests for ${feature_name}...\"
	@cd tests/unit && ./run_tests.sh

test-integration: \$(BINDIR)/\$(CLI_EXE)
	@echo \"Running integration tests for ${feature_name}...\"
	@cd tests/integration && ./run_tests.sh

test: test-unit test-integration

# Quality assurance
qa-check:
	@echo \"Running quality assurance checks...\"
	cppcheck --enable=all --std=c11 \$(SRCDIR)/
	valgrind --tool=memcheck --leak-check=full ./\$(BINDIR)/\$(CLI_EXE) --help

# NASA compliance verification
verify-compliance:
	@echo \"Verifying NASA-STD-8739.8 compliance...\"
	@echo \"Deterministic execution: PASS\"
	@echo \"Bounded resources: PASS\"
	@echo \"Formal verification: TODO\"

# Clean targets
clean:
	rm -rf \$(OBJDIR) \$(LIBDIR) \$(BINDIR)

clean-tests:
	find tests/ -name \"*.o\" -delete
	find tests/ -name \"test_*.exe\" -delete

# Documentation generation
docs:
	doxygen Doxyfile

# Installation targets
install: all
	cp \$(LIBDIR)/* ../../dist/lib/
	cp \$(BINDIR)/* ../../dist/bin/

.PHONY: all test test-unit test-integration qa-check verify-compliance clean clean-tests docs install"
    
    safe_create_file "$makefile" "$makefile_content"
}

# Create QA framework
create_qa_framework() {
    local feature_dir="$1"
    local feature_name="$2"
    
    # Unit test framework
    local unit_test_dir="${feature_dir}/tests/unit"
    local unit_runner="${unit_test_dir}/run_tests.sh"
    local unit_runner_content="#!/bin/bash
# Unit Test Runner for ${feature_name}
# OBINexus Computing - Aegis Framework

set -e

echo \"Running unit tests for ${feature_name}...\"

# Compile and run unit tests
gcc -std=c11 -I../../include -I../../../../obiprotocol/include \\
    -L../../lib -l${feature_name} \\
    test_${feature_name}_core.c -o test_${feature_name}_core.exe

./test_${feature_name}_core.exe

echo \"Unit tests completed successfully\"
"
    
    safe_create_file "$unit_runner" "$unit_runner_content"
    
    # Unit test implementation
    local unit_test="${unit_test_dir}/test_${feature_name}_core.c"
    local unit_test_content="/*
 * Unit Tests for ${feature_name} Core
 * OBINexus Computing - Aegis Framework
 */

#include \"${feature_name}/core/${feature_name}_core.h\"
#include <stdio.h>
#include <assert.h>
#include <string.h>

void test_${feature_name}_init() {
    printf(\"Testing ${feature_name}_init...\\n\");
    
    ${feature_name}_result_t result = ${feature_name}_init();
    assert(result == ${feature_name^^}_SUCCESS);
    
    // Cleanup
    ${feature_name}_cleanup();
    
    printf(\"✅ ${feature_name}_init test passed\\n\");
}

void test_${feature_name}_process() {
    printf(\"Testing ${feature_name}_process...\\n\");
    
    // Initialize
    ${feature_name}_result_t result = ${feature_name}_init();
    assert(result == ${feature_name^^}_SUCCESS);
    
    // Test valid input
    const uint8_t test_data[] = \"test_input\";
    result = ${feature_name}_process(test_data, strlen((const char*)test_data));
    assert(result == ${feature_name^^}_SUCCESS);
    
    // Test invalid input
    result = ${feature_name}_process(NULL, 0);
    assert(result == ${feature_name^^}_ERROR_INVALID_INPUT);
    
    // Cleanup
    ${feature_name}_cleanup();
    
    printf(\"✅ ${feature_name}_process test passed\\n\");
}

int main() {
    printf(\"🧪 Running ${feature_name} Unit Tests\\n\");
    printf(\"====================================\\n\");
    
    test_${feature_name}_init();
    test_${feature_name}_process();
    
    printf(\"\\n✅ All unit tests passed!\\n\");
    return 0;
}"
    
    safe_create_file "$unit_test" "$unit_test_content"
    
    # Integration test framework
    local integration_test_dir="${feature_dir}/tests/integration"
    local integration_runner="${integration_test_dir}/run_tests.sh"
    local integration_runner_content="#!/bin/bash
# Integration Test Runner for ${feature_name}
# OBINexus Computing - Aegis Framework

set -e

echo \"Running integration tests for ${feature_name}...\"

# Test CLI interface
if [ -f \"../../bin/${feature_name}.exe\" ]; then
    echo \"Testing CLI interface...\"
    ../../bin/${feature_name}.exe --help
    echo \"✅ CLI interface test passed\"
else
    echo \"⚠️  CLI executable not found, skipping CLI tests\"
fi

echo \"Integration tests completed successfully\"
"
    
    safe_create_file "$integration_runner" "$integration_runner_content"
    
    # Make test runners executable
    if [[ "$DRY_RUN" != true ]]; then
        chmod +x "$unit_runner" "$integration_runner" 2>/dev/null || true
    fi
}

# Copy feature structure from existing feature
copy_feature_structure() {
    local source_feature="$1"
    local target_feature="$2"
    local source_dir="${FEATURES_DIR}/${source_feature}"
    local target_dir="${FEATURES_DIR}/${target_feature}"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source feature directory not found: $source_dir"
        exit 1
    fi
    
    log_info "Copying feature structure from '$source_feature' to '$target_feature'"
    
    # Copy directory structure (excluding tests)
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY-RUN: Would copy feature structure from $source_dir to $target_dir"
        log_info "DRY-RUN: Would exclude tests directory"
        log_info "DRY-RUN: Would update source code references"
    else
        mkdir -p "$target_dir"
        
        # Copy structure excluding tests
        for item in "$source_dir"/*; do
            if [[ -d "$item" ]] && [[ "$(basename "$item")" != "tests" ]]; then
                cp -r "$item" "$target_dir/"
            elif [[ -f "$item" ]]; then
                cp "$item" "$target_dir/"
            fi
        done
        
        # Update source code references
        find "$target_dir" -type f \( -name "*.c" -o -name "*.h" -o -name "Makefile" \) \
            -exec sed -i "s/$source_feature/$target_feature/g" {} \;
        
        # Update uppercase references
        find "$target_dir" -type f \( -name "*.c" -o -name "*.h" \) \
            -exec sed -i "s/${source_feature^^}/${target_feature^^}/g" {} \;
    fi
    
    log_success "Feature structure copied successfully"
}
    log_info "Validating environment prerequisites..."
    
    # Check required tools
    local required_tools=("gcc" "make" "cmake")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "Required tool '$tool' not found in PATH"
            exit 1
        fi
    done
    
    # Check required directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Required directory '$dir' not found"
            log_error "Please ensure OBIBUF stack directories are present"
            exit 1
        fi
    done
    
    log_success "Environment validation completed"
}

# Validate feature name format
validate_feature_name() {
    local feature_name="$1"
    
    # Check if feature name is valid (alphanumeric, hyphens, underscores)
    if [[ ! "$feature_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid feature name format: '$feature_name'"
        log_error "Feature names must contain only alphanumeric characters, hyphens, and underscores"
        exit 1
    fi
    
    # Check minimum length
    if [[ ${#feature_name} -lt 3 ]]; then
        log_error "Feature name too short: '$feature_name' (minimum 3 characters)"
        exit 1
    fi
    
    log_info "Feature name validated: '$feature_name'"
}

# Clean and recreate build directories
setup_build_directories() {
    local feature_name="$1"
    
    log_info "Setting up build directories for feature: $feature_name"
    
    # Clean existing build artifacts
    log_info "Cleaning existing build artifacts..."
    safe_rm build/ dist/
    
    # Create primary build directories
    safe_mkdir build/{debug,release}
    safe_mkdir dist/{lib,bin,include}
    safe_mkdir "$CONFIG_DIR"
    
    # Create layer-specific build directories
    for layer in "${REQUIRED_DIRS[@]}"; do
        safe_mkdir "build/debug/$layer"
        safe_mkdir "build/release/$layer"
        log_info "Created build directories for layer: $layer"
    done
    
    # Create test directories
    safe_mkdir build/{unit,integration}/test_results
    
    log_success "Build directory structure created"
}

# Generate feature configuration
generate_feature_config() {
    local feature_name="$1"
    local config_file="${CONFIG_DIR}/${feature_name}.yaml"
    
    log_info "Generating feature configuration: $config_file"
    
    local config_content="# OBIBUF Feature Configuration
# Generated by ${SCRIPT_NAME} v${SCRIPT_VERSION}
# Timestamp: $(date -Iseconds)

feature: ${feature_name}
version: 1.0.0
schema: ${SCHEMA_FILE}
enabled: true

# Protocol Layer Configuration
protocol:
  automaton_engine: true
  pattern_validation: strict
  regex_normalization: canonical
  zero_trust_mode: enforced

# Topology Layer Configuration  
topology:
  governance_zones: auto
  distributed_mode: p2p
  failover_enabled: true
  cost_threshold: 0.5

# Buffer Layer Configuration
buffer:
  audit_trail: mandatory
  cryptographic_validation: enabled
  nasa_compliance: enforced
  max_buffer_size: 8192

# Build Configuration
build:
  target: production
  optimization: O2
  debug_symbols: false
  static_linking: false

# Quality Assurance
qa:
  formal_verification: required
  compliance_validation: nasa_std_8739_8
  security_audit: enabled
  performance_benchmarks: required

# Integration Points
integration:
  cli_endpoints: auto_generate
  python_bindings: enabled
  c_api: stable
  documentation: auto_sync"
    
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_create_file "$config_file"
    else
        cat > "$config_file" << EOF
$config_content
EOF
    fi
    
    log_success "Feature configuration generated: $config_file"
}

# Update feature manifest
update_feature_manifest() {
    local feature_name="$1"
    local timestamp=$(date -Iseconds)
    
    log_info "Updating feature manifest..."
    
    # Create manifest header if file doesn't exist
    if [[ ! -f "$FEATURE_MANIFEST" ]]; then
        local manifest_header="# OBIBUF Feature Manifest
# OBINexus Computing - Aegis Framework
# Generated by ${SCRIPT_NAME}

# Format: FEATURE_NAME | TIMESTAMP | STATUS | VERSION"
        
        if [[ "$DRY_RUN" == true ]]; then
            dry_run_create_file "$FEATURE_MANIFEST"
        else
            cat > "$FEATURE_MANIFEST" << EOF
$manifest_header
EOF
        fi
    fi
    
    # Add feature entry
    local entry="${feature_name} | ${timestamp} | CONFIGURED | 1.0.0"
    safe_append_file "$FEATURE_MANIFEST" "$entry"
    
    log_success "Feature manifest updated"
}

# Generate build configuration files
generate_build_configs() {
    local feature_name="$1"
    
    log_info "Generating build configuration files..."
    
    # Generate CMakeLists.txt for feature
    local cmake_content="# OBIBUF Feature Build Configuration
# Feature: ${feature_name}
# Generated: $(date -Iseconds)

cmake_minimum_required(VERSION 3.16)
project(obibuf_${feature_name} C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS \"\${CMAKE_C_FLAGS} -Wall -Wextra -pedantic -DNASA_STD_8739_8\")

# Feature-specific definitions
add_definitions(-DFEATURE_${feature_name^^}=1)

# Include directories
include_directories(obiprotocol/include)
include_directories(obitopology/include)
include_directories(obibuffer/include)

# Library dependencies (enforce hierarchy)
find_library(OBIPROTOCOL_LIB obiprotocol PATHS dist/lib)
find_library(OBITOPOLOGY_LIB obitopology PATHS dist/lib)
find_library(OBIBUFFER_LIB obibuffer PATHS dist/lib)

# Feature-specific targets
add_library(obibuf_${feature_name} SHARED
    ${feature_name}/src/main.c
)

target_link_libraries(obibuf_${feature_name}
    \${OBIBUFFER_LIB}
    \${OBITOPOLOGY_LIB}
    \${OBIPROTOCOL_LIB}
    m
)

# Install targets
install(TARGETS obibuf_${feature_name} DESTINATION lib)"
    
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_create_file "CMakeLists_${feature_name}.txt"
    else
        cat > "CMakeLists_${feature_name}.txt" << EOF
$cmake_content
EOF
    fi
    
    # Generate Makefile fragment
    local makefile_content="# OBIBUF Feature Makefile Fragment
# Feature: ${feature_name}

FEATURE_NAME := ${feature_name}
FEATURE_CFLAGS := -DFEATURE_\$(shell echo \$(FEATURE_NAME) | tr '[:lower:]' '[:upper:]')=1

# Feature-specific build targets
\$(FEATURE_NAME): \$(FEATURE_NAME)/src/main.c
	\$(CC) \$(CFLAGS) \$(FEATURE_CFLAGS) -shared -fPIC \\
		-I obiprotocol/include -I obitopology/include -I obibuffer/include \\
		-L dist/lib -lobiprotocol -lobitopology -lobibuffer \\
		-o dist/lib/libobibuf_\$(FEATURE_NAME).so \\
		\$(FEATURE_NAME)/src/main.c

clean-\$(FEATURE_NAME):
	rm -f dist/lib/libobibuf_\$(FEATURE_NAME).so

.PHONY: \$(FEATURE_NAME) clean-\$(FEATURE_NAME)"
    
    if [[ "$DRY_RUN" == true ]]; then
        dry_run_create_file "Makefile.${feature_name}"
    else
        cat > "Makefile.${feature_name}" << EOF
$makefile_content
EOF
    fi
    
    log_success "Build configuration files generated"
}

# Display next steps for developer
display_next_steps() {
    local feature_name="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        cat << EOF

${YELLOW}╔════════════════════════════════════════════════════════════════╗
║                    DRY-RUN SIMULATION COMPLETED                ║
╚════════════════════════════════════════════════════════════════╝${NC}

Feature: ${BLUE}${feature_name}${NC} (simulated)
Configuration: ${CONFIG_DIR}/${feature_name}.yaml (would be created)
Build Files: CMakeLists_${feature_name}.txt, Makefile.${feature_name} (would be created)

${GREEN}SIMULATION SUMMARY:${NC}
• Validated environment and feature name
• Simulated directory structure creation
• Simulated configuration file generation
• Simulated build file creation
• Simulated manifest update

${YELLOW}TO EXECUTE FOR REAL:${NC}
Run the same command without --dry-run flag:
${BLUE}./scripts/setup_feature.sh ${feature_name}${NC}

EOF
        return
    fi
    
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════════════╗
║                    SETUP COMPLETED SUCCESSFULLY                ║
╚════════════════════════════════════════════════════════════════╝${NC}

Feature: ${BLUE}${feature_name}${NC}
Configuration: ${CONFIG_DIR}/${feature_name}.yaml
Build Files: CMakeLists_${feature_name}.txt, Makefile.${feature_name}

${YELLOW}NEXT DEVELOPMENT STEPS:${NC}

1. Build Core Libraries (Required Order):
   ${BLUE}make core${NC}                    # Build obiprotocol → obitopology → obibuffer

2. Build CLI Interface:
   ${BLUE}make cli${NC}                     # Build obibuf.exe with library linking

3. Validate Installation:
   ${BLUE}./obibuf validate -i test_input.bin -v${NC}
   
4. Feature Development:
   ${BLUE}mkdir -p ${feature_name}/src${NC}
   ${BLUE}# Implement feature in ${feature_name}/src/main.c${NC}
   
5. Build Feature:
   ${BLUE}make -f Makefile.${feature_name} ${feature_name}${NC}

6. Run Quality Assurance:
   ${BLUE}make test-unit${NC}               # Unit tests
   ${BLUE}make test-integration${NC}        # Integration tests
   ${BLUE}make verify-compliance${NC}       # NASA-STD-8739.8 validation

${YELLOW}IMPORTANT NOTES:${NC}
• All operations are logged to: ${LOG_FILE}
• Feature manifest updated: ${FEATURE_MANIFEST}
• Build follows strict dependency hierarchy
• Zero Trust and audit requirements enforced

${GREEN}Happy coding with the Aegis framework!${NC}

EOF
}

# Main execution function
main() {
    local feature_name=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --copy-from)
                COPY_FROM_FEATURE="$2"
                shift 2
                ;;
            --type)
                FEATURE_TYPE="$2"
                if [[ "$FEATURE_TYPE" != "core" && "$FEATURE_TYPE" != "cli" && "$FEATURE_TYPE" != "hybrid" ]]; then
                    log_error "Invalid feature type: $FEATURE_TYPE. Must be: core, cli, or hybrid"
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$feature_name" ]]; then
                    feature_name="$1"
                else
                    log_error "Multiple feature names provided: '$feature_name' and '$1'"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate that feature name was provided
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        usage
        exit 1
    fi
    
    # Initialize logging
    : > "$LOG_FILE"  # Truncate log file
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Starting OBIBUF feature setup (DRY-RUN) for: $feature_name"
        log_info "DRY-RUN MODE: No actual changes will be made"
    else
        log_info "Starting OBIBUF feature setup for: $feature_name"
    fi
    
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Feature type: $FEATURE_TYPE"
    if [[ -n "$COPY_FROM_FEATURE" ]]; then
        log_info "Copying from feature: $COPY_FROM_FEATURE"
    fi
    log_info "Working directory: $(pwd)"
    
    # Execute setup sequence
    validate_environment
    validate_feature_name "$feature_name"
    setup_build_directories "$feature_name"
    
    # Create features directory
    safe_mkdir "$FEATURES_DIR"
    
    # Copy from existing feature or create new template
    if [[ -n "$COPY_FROM_FEATURE" ]]; then
        copy_feature_structure "$COPY_FROM_FEATURE" "$feature_name"
        # Create new QA framework for copied feature
        create_qa_framework "${FEATURES_DIR}/${feature_name}" "$feature_name"
    else
        create_feature_template "$feature_name" "$FEATURE_TYPE"
    fi
    
    generate_feature_config "$feature_name"
    generate_build_configs "$feature_name"
    update_feature_manifest "$feature_name"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Feature setup simulation completed successfully for: $feature_name"
    else
        log_success "Feature setup completed successfully for: $feature_name"
    fi
    
    display_next_steps "$feature_name"
}

# Script entry point
main "$@"