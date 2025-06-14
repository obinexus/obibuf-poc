#!/bin/bash
# OBIBUF Production Feature Setup Script
# OBINexus Computing - Aegis Framework
# 
# Configures multi-layered protocol stack for new feature integration
# Enforces dependency hierarchy: obibuffer → obitopology → obiprotocol

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="setup_feature.sh"
readonly SCRIPT_VERSION="1.1.0"
readonly LOG_FILE="setup.log"
readonly FEATURE_MANIFEST="dist/feature_manifest.txt"
readonly CONFIG_DIR="configs"
readonly SCHEMA_FILE="obibuf.schema.yaml"

# Required directories for OBIBUF stack
readonly REQUIRED_DIRS=("obiprotocol" "obitopology" "obibuffer")

# Global flags
DRY_RUN=false

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

OPTIONS:
    --dry-run       Simulate operations without making actual changes
    -h, --help      Show this help message

PARAMETERS:
    feature_name    Name of the feature (e.g., protocol-state-validation)

EXAMPLES:
    ${SCRIPT_NAME} protocol-state-validation
    ${SCRIPT_NAME} --dry-run topology-burst-mode
    ${SCRIPT_NAME} buffer-audit-enhancement

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
validate_environment() {
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
    log_info "Working directory: $(pwd)"
    
    # Execute setup sequence
    validate_environment
    validate_feature_name "$feature_name"
    setup_build_directories "$feature_name"
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