# OBIBUF Root Makefile
# OBINexus Computing - Aegis Framework
# 
# Builds all layers in proper dependency order:
# obiprotocol → obitopology → obibuffer

.PHONY: all core cli clean test help

# Build all components
all: core cli

# Build core libraries in dependency order
core: obiprotocol obitopology obibuffer

# Individual layer targets
obiprotocol:
	@echo "Building obiprotocol layer..."
	$(MAKE) -C obiprotocol

obitopology: obiprotocol
	@echo "Building obitopology layer..."
	$(MAKE) -C obitopology

obibuffer: obitopology
	@echo "Building obibuffer layer..."
	$(MAKE) -C obibuffer

# CLI interface (placeholder)
cli: core
	@echo "CLI interface build target - TODO: Implement obibuf.exe"

# Clean all layers
clean:
	$(MAKE) -C obiprotocol clean
	$(MAKE) -C obitopology clean
	$(MAKE) -C obibuffer clean
	rm -rf dist/

# Test targets
test-unit:
	@echo "Unit test target - TODO: Implement"

test-integration:
	@echo "Integration test target - TODO: Implement"

verify-compliance:
	@echo "NASA-STD-8739.8 compliance verification - TODO: Implement"

# Help target
help:
	@echo "OBIBUF Build System - Available Targets:"
	@echo "  all              - Build complete protocol stack"
	@echo "  core             - Build core libraries (obiprotocol → obitopology → obibuffer)"
	@echo "  cli              - Build CLI interface"
	@echo "  obiprotocol      - Build protocol layer only"
	@echo "  obitopology      - Build topology layer only"
	@echo "  obibuffer        - Build buffer layer only"
	@echo "  clean            - Clean all build artifacts"
	@echo "  test-unit        - Run unit tests"
	@echo "  test-integration - Run integration tests"
	@echo "  verify-compliance- Verify NASA-STD-8739.8 compliance"
	@echo "  help             - Show this help message"
