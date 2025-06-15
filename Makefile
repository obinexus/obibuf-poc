# OBIBuf Unified CLI Makefile
# OBINexus Computing - Aegis Framework
# Links against obiprotocol, obitopology, and obibuffer libraries

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -DNASA_STD_8739_8
INCLUDES = -Iobiprotocol/include -Iobitopology/include -Iobibuffer/include
LIBDIR = dist/lib
BINDIR = bin
SRCDIR = cli

# Library dependencies (hierarchical linking order)
LIBS = -L$(LIBDIR) -lobibuffer -lobitopology -lobiprotocol -lm

# Source and object files
CLI_SOURCE = $(SRCDIR)/obibuf_main.c
CLI_OBJECT = $(CLI_SOURCE:.c=.o)
CLI_EXECUTABLE = $(BINDIR)/obibuf.exe

# Prerequisites - ensure all layer libraries exist (OBINexus standard)
PROTOCOL_LIB = $(LIBDIR)/obiprotocol.so
TOPOLOGY_LIB = $(LIBDIR)/obitopology.so  
BUFFER_LIB = $(LIBDIR)/obibuffer.so

# Main targets
.PHONY: all cli clean install test help check-libs

all: check-libs cli

# Primary CLI build target
cli: $(CLI_EXECUTABLE)

$(CLI_EXECUTABLE): $(CLI_OBJECT) $(PROTOCOL_LIB) $(TOPOLOGY_LIB) $(BUFFER_LIB) | $(BINDIR)
	@echo "🔗 Linking unified OBIBuf CLI..."
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

# Dependency verification
check-libs:
	@echo "🔍 Checking library dependencies..."
	@if [ ! -f "$(PROTOCOL_LIB)" ]; then \
		echo "❌ Missing: $(PROTOCOL_LIB)"; \
		echo "   Build with: make -C obiprotocol"; \
		exit 1; \
	fi
	@if [ ! -f "$(TOPOLOGY_LIB)" ]; then \
		echo "❌ Missing: $(TOPOLOGY_LIB)"; \
		echo "   Build with: make -C obitopology"; \
		exit 1; \
	fi
	@if [ ! -f "$(BUFFER_LIB)" ]; then \
		echo "❌ Missing: $(BUFFER_LIB)"; \
		echo "   Build with: make -C obibuffer"; \
		exit 1; \
	fi
	@echo "✅ All layer libraries present"

check-includes:
	@echo "🔍 Verifying include directories..."
	@for dir in obiprotocol/include obitopology/include obibuffer/include; do \
		if [ ! -d "$$dir" ]; then \
			echo "❌ Missing include directory: $$dir"; \
			exit 1; \
		fi \
	done
	@echo "✅ All include directories present"

# Build entire stack from scratch
build-stack:
	@echo "🏗️  Building complete OBIBuf stack..."
	$(MAKE) -C obiprotocol clean all
	$(MAKE) -C obitopology clean all  
	$(MAKE) -C obibuffer clean all
	$(MAKE) cli

# Installation target
install: $(CLI_EXECUTABLE)
	@echo "📦 Installing OBIBuf CLI..."
	@mkdir -p /usr/local/bin
	cp $(CLI_EXECUTABLE) /usr/local/bin/obibuf
	@echo "✅ Installed: /usr/local/bin/obibuf"

# Testing targets
test: $(CLI_EXECUTABLE)
	@echo "🧪 Running CLI integration tests..."
	$(CLI_EXECUTABLE) version
	$(CLI_EXECUTABLE) help
	@echo "✅ Basic CLI tests passed"

test-protocol: $(CLI_EXECUTABLE)
	@echo "🧪 Testing protocol layer integration..."
	@echo "test_input" > test_input.tmp
	$(CLI_EXECUTABLE) protocol validate test_input.tmp || true
	$(CLI_EXECUTABLE) protocol normalize "test/../path" || true
	@rm -f test_input.tmp
	@echo "✅ Protocol integration tests completed"

test-topology: $(CLI_EXECUTABLE)
	@echo "🧪 Testing topology layer integration..."
	$(CLI_EXECUTABLE) topology metrics || true
	@echo "✅ Topology integration tests completed"

test-buffer: $(CLI_EXECUTABLE)
	@echo "🧪 Testing buffer layer integration..."
	$(CLI_EXECUTABLE) buffer audit test_audit.log || true
	@rm -f test_audit.log
	@echo "✅ Buffer integration tests completed"

test-all: test test-protocol test-topology test-buffer

# Debugging and analysis
debug: CFLAGS += -g -DDEBUG
debug: clean cli
	@echo "🐛 Debug build completed"

analyze: $(CLI_SOURCE)
	@echo "🔍 Running static analysis..."
	cppcheck --enable=all $(CLI_SOURCE) || true
	@echo "✅ Static analysis completed"

# Clean targets
clean:
	@echo "🧹 Cleaning CLI build artifacts..."
	rm -f $(CLI_OBJECT)
	rm -f $(CLI_EXECUTABLE)
	rm -f test_*.tmp test_*.log

clean-all: clean
	@echo "🧹 Cleaning all layers..."
	$(MAKE) -C obiprotocol clean
	$(MAKE) -C obitopology clean
	$(MAKE) -C obibuffer clean

# Information and debugging
info:
	@echo "OBIBuf CLI Build Configuration"
	@echo "=============================="
	@echo "Compiler: $(CC)"
	@echo "Flags: $(CFLAGS)"
	@echo "Includes: $(INCLUDES)"
	@echo "Libraries: $(LIBS)"
	@echo "Source: $(CLI_SOURCE)"
	@echo "Executable: $(CLI_EXECUTABLE)"
	@echo "Dependencies:"
	@echo "  - $(PROTOCOL_LIB)"
	@echo "  - $(TOPOLOGY_LIB)"
	@echo "  - $(BUFFER_LIB)"

help:
	@echo "OBIBuf CLI Build System"
	@echo "======================="
	@echo "Available targets:"
	@echo "  all          - Build CLI with dependency checking"
	@echo "  cli          - Build only the CLI executable"
	@echo "  build-stack  - Build complete layer stack + CLI"
	@echo "  install      - Install CLI to /usr/local/bin"
	@echo "  test         - Run basic integration tests"
	@echo "  test-all     - Run comprehensive layer tests"
	@echo "  debug        - Build with debug symbols"
	@echo "  analyze      - Run static code analysis"
	@echo "  clean        - Clean CLI build artifacts"
	@echo "  clean-all    - Clean all layers and CLI"
	@echo "  info         - Show build configuration"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - All layer libraries must be built first"
	@echo "  - Include directories must exist"
	@echo "  - GCC with C11 support required"

# Dependencies for proper rebuild
$(CLI_OBJECT): obiprotocol/include/obiprotocol.h \
               obitopology/include/obitopology.h \
               obibuffer/include/obibuffer.h