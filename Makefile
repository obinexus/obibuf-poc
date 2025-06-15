# OBIBuf Unified CLI Makefile
# OBINexus Computing - Aegis Framework
# Links against obiprotocol, obitopology, and obibuffer libraries
# riftlang.exe → .so.a → rift.exe → gosilang toolchain

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -DNASA_STD_8739_8
INCLUDES = -Iobiprotocol/include -Iobitopology/include -Iobibuffer/include
LIBDIR = dist/lib
BINDIR = bin
SRCDIR = cli

# Library dependencies (OBINexus standard - NO lib prefix)
LIBS = -L$(LIBDIR) -lobibuffer -lobitopology -lobiprotocol -lm

# Source and object files
CLI_SOURCE = $(SRCDIR)/obibuf_main.c
CLI_OBJECT = $(CLI_SOURCE:.c=.o)
CLI_EXECUTABLE = $(BINDIR)/obibuf.exe

# Prerequisites - OBINexus standard library names
PROTOCOL_LIB = $(LIBDIR)/obiprotocol.so
TOPOLOGY_LIB = $(LIBDIR)/obitopology.so  
BUFFER_LIB = $(LIBDIR)/obibuffer.so

# Static library variants for post-build distribution
PROTOCOL_STATIC = $(LIBDIR)/obiprotocol.a
TOPOLOGY_STATIC = $(LIBDIR)/obitopology.a
BUFFER_STATIC = $(LIBDIR)/obibuffer.a

# Main targets
.PHONY: all cli clean install test help check-libs build-layers post-build-copy core

all: build-layers post-build-copy check-libs cli

# Core build target - builds all layers in dependency order
core: build-layers post-build-copy

# Build all layer libraries in correct dependency order
build-layers:
	@echo "🔨 Building OBINexus layers in dependency order..."
	@echo "📦 Building obiprotocol (foundation layer)..."
	$(MAKE) -C obiprotocol clean all
	@echo "📦 Building obitopology (middle layer)..."
	$(MAKE) -C obitopology clean all
	@echo "📦 Building obibuffer (top layer)..."
	$(MAKE) -C obibuffer clean all
	@echo "✅ All layers built successfully"

# Post-build copy mechanism - consolidate all obi*.so/.a/.dll files
post-build-copy:
	@echo "📋 Post-build copy: Consolidating OBI libraries..."
	@mkdir -p $(LIBDIR)
	
	# Copy shared libraries (.so) from each layer
	@if [ -f obiprotocol/dist/lib/obiprotocol.so ]; then \
		cp obiprotocol/dist/lib/obiprotocol.so $(LIBDIR)/; \
		echo "✅ Copied obiprotocol.so"; \
	elif [ -f obiprotocol/$(LIBDIR)/libobiprotocol.so ]; then \
		cp obiprotocol/$(LIBDIR)/libobiprotocol.so $(LIBDIR)/obiprotocol.so; \
		echo "✅ Copied and renamed libobiprotocol.so → obiprotocol.so"; \
	fi
	
	@if [ -f obitopology/dist/lib/obitopology.so ]; then \
		cp obitopology/dist/lib/obitopology.so $(LIBDIR)/; \
		echo "✅ Copied obitopology.so"; \
	elif [ -f obitopology/$(LIBDIR)/libobitopology.so ]; then \
		cp obitopology/$(LIBDIR)/libobitopology.so $(LIBDIR)/obitopology.so; \
		echo "✅ Copied and renamed libobitopology.so → obitopology.so"; \
	fi
	
	@if [ -f obibuffer/dist/lib/obibuffer.so ]; then \
		cp obibuffer/dist/lib/obibuffer.so $(LIBDIR)/; \
		echo "✅ Copied obibuffer.so"; \
	elif [ -f obibuffer/$(LIBDIR)/libobibuffer.so ]; then \
		cp obibuffer/$(LIBDIR)/libobibuffer.so $(LIBDIR)/obibuffer.so; \
		echo "✅ Copied and renamed libobibuffer.so → obibuffer.so"; \
	fi
	
	# Copy static libraries (.a) from each layer
	@if [ -f obiprotocol/dist/lib/obiprotocol.a ]; then \
		cp obiprotocol/dist/lib/obiprotocol.a $(LIBDIR)/; \
		echo "✅ Copied obiprotocol.a"; \
	elif [ -f obiprotocol/$(LIBDIR)/libobiprotocol.a ]; then \
		cp obiprotocol/$(LIBDIR)/libobiprotocol.a $(LIBDIR)/obiprotocol.a; \
		echo "✅ Copied and renamed libobiprotocol.a → obiprotocol.a"; \
	fi
	
	@if [ -f obitopology/dist/lib/obitopology.a ]; then \
		cp obitopology/dist/lib/obitopology.a $(LIBDIR)/; \
		echo "✅ Copied obitopology.a"; \
	elif [ -f obitopology/$(LIBDIR)/libobitopology.a ]; then \
		cp obitopology/$(LIBDIR)/libobitopology.a $(LIBDIR)/obitopology.a; \
		echo "✅ Copied and renamed libobitopology.a → obitopology.a"; \
	fi
	
	@if [ -f obibuffer/dist/lib/obibuffer.a ]; then \
		cp obibuffer/dist/lib/obibuffer.a $(LIBDIR)/; \
		echo "✅ Copied obibuffer.a"; \
	elif [ -f obibuffer/$(LIBDIR)/libobibuffer.a ]; then \
		cp obibuffer/$(LIBDIR)/libobibuffer.a $(LIBDIR)/obibuffer.a; \
		echo "✅ Copied and renamed libobibuffer.a → obibuffer.a"; \
	fi
	
	# Windows DLL support (.dll) - polybuild compatibility
	@for dll_file in $$(find . -name "obi*.dll" 2>/dev/null || true); do \
		if [ -f "$$dll_file" ]; then \
			cp "$$dll_file" $(LIBDIR)/; \
			echo "✅ Copied $$(basename $$dll_file)"; \
		fi; \
	done
	
	@echo "📋 Post-build copy completed - all obi*.so/.a/.dll files consolidated"

# Primary CLI build target
cli: $(CLI_EXECUTABLE)

$(CLI_EXECUTABLE): $(CLI_OBJECT) $(PROTOCOL_LIB) $(TOPOLOGY_LIB) $(BUFFER_LIB) | $(BINDIR)
	@echo "🔗 Linking unified OBIBuf CLI (nlink orchestration)..."
	$(CC) $(CLI_OBJECT) $(LIBS) -o $@
	@echo "✅ Built: $@"

# Compile CLI source
$(CLI_OBJECT): $(CLI_SOURCE) | check-includes
	@echo "🔨 Compiling OBIBuf CLI source..."
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Directory creation
$(BINDIR):
	@echo "📁 Creating binary directory..."
	mkdir -p $(BINDIR)

# Dependency verification - OBINexus standard naming
check-libs:
	@echo "🔍 Checking library dependencies (OBINexus standard)..."
	@if [ ! -f "$(PROTOCOL_LIB)" ]; then \
		echo "❌ Missing: $(PROTOCOL_LIB)"; \
		echo "   Build with: make core (builds all layers)"; \
		exit 1; \
	fi
	@if [ ! -f "$(TOPOLOGY_LIB)" ]; then \
		echo "❌ Missing: $(TOPOLOGY_LIB)"; \
		echo "   Build with: make core (builds all layers)"; \
		exit 1; \
	fi
	@if [ ! -f "$(BUFFER_LIB)" ]; then \
		echo "❌ Missing: $(BUFFER_LIB)"; \
		echo "   Build with: make core (builds all layers)"; \
		exit 1; \
	fi
	@echo "✅ All layer libraries present (OBINexus standard)"

check-includes:
	@echo "🔍 Verifying include directories..."
	@for dir in obiprotocol/include obitopology/include obibuffer/include; do \
		if [ ! -d "$$dir" ]; then \
			echo "❌ Missing include directory: $$dir"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All include directories present"

# Clean all build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(BINDIR)
	rm -f $(CLI_OBJECT)
	$(MAKE) -C obiprotocol clean 2>/dev/null || true
	$(MAKE) -C obitopology clean 2>/dev/null || true
	$(MAKE) -C obibuffer clean 2>/dev/null || true
	rm -f $(LIBDIR)/obi*.so $(LIBDIR)/obi*.a $(LIBDIR)/obi*.dll
	@echo "✅ Clean completed"

# Install target for production deployment
install: all
	@echo "📦 Installing OBIBuf to system..."
	mkdir -p /usr/local/lib /usr/local/bin /usr/local/include
	cp $(LIBDIR)/obi*.so /usr/local/lib/
	cp $(LIBDIR)/obi*.a /usr/local/lib/
	cp $(CLI_EXECUTABLE) /usr/local/bin/
	cp -r obiprotocol/include/* /usr/local/include/
	cp -r obitopology/include/* /usr/local/include/
	cp -r obibuffer/include/* /usr/local/include/
	ldconfig
	@echo "✅ Installation completed"

# Help target
help:
	@echo "OBINexus OBIBuf Build System"
	@echo "============================="
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Build everything (layers + CLI)"
	@echo "  core         - Build core libraries only"
	@echo "  cli          - Build CLI executable only"
	@echo "  check-libs   - Verify library dependencies"
	@echo "  clean        - Clean all build artifacts"
	@echo "  install      - Install to system"
	@echo "  help         - Show this help"
	@echo ""
	@echo "OBINexus toolchain: riftlang.exe → .so.a → rift.exe → gosilang"
	@echo "Build orchestration: nlink → polybuild"
