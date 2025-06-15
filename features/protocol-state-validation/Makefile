# protocol-state-validation Feature Makefile
# OBINexus Computing - Aegis Framework
# Generated: 2025-06-15T00:23:54+01:00
# Feature Type: core

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC -DNASA_STD_8739_8
INCLUDES = -Iinclude -I../../obiprotocol/include -I../../obitopology/include -I../../obibuffer/include
SRCDIR = src
OBJDIR = obj
LIBDIR = lib
BINDIR = bin

# Source files
CORE_SOURCES = $(wildcard $(SRCDIR)/core/*.c)
CLI_SOURCES = $(wildcard $(SRCDIR)/cli/*.c)
CORE_OBJECTS = $(CORE_SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
CLI_OBJECTS = $(CLI_SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Library and executable names
CORE_LIB = libprotocol-state-validation.so
CORE_STATIC = libprotocol-state-validation.a
CLI_EXE = protocol-state-validation.exe

# External library dependencies
LIBS = -L../../dist/lib -lobiprotocol -lobitopology -lobibuffer -lm\nall: $(LIBDIR)/$(CORE_LIB) $(LIBDIR)/$(CORE_STATIC)

# Core library targets
$(LIBDIR)/$(CORE_LIB): $(CORE_OBJECTS) | $(LIBDIR)
	$(CC) -shared -o $@ $(CORE_OBJECTS) $(LIBS)

$(LIBDIR)/$(CORE_STATIC): $(CORE_OBJECTS) | $(LIBDIR)
	ar rcs $@ $(CORE_OBJECTS)

# CLI executable target
$(BINDIR)/$(CLI_EXE): $(CLI_OBJECTS) $(LIBDIR)/$(CORE_LIB) | $(BINDIR)
	$(CC) -o $@ $(CLI_OBJECTS) -L$(LIBDIR) -lprotocol-state-validation $(LIBS)

# Object file compilation
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Directory creation
$(OBJDIR):
	mkdir -p $(OBJDIR)/core $(OBJDIR)/cli

$(LIBDIR):
	mkdir -p $(LIBDIR)

$(BINDIR):
	mkdir -p $(BINDIR)

# Test targets
test-unit: $(LIBDIR)/$(CORE_LIB)
	@echo "Running unit tests for protocol-state-validation..."
	@cd tests/unit && ./run_tests.sh

test-integration: $(BINDIR)/$(CLI_EXE)
	@echo "Running integration tests for protocol-state-validation..."
	@cd tests/integration && ./run_tests.sh

test: test-unit test-integration

# Clean targets
clean:
	rm -rf $(OBJDIR) $(LIBDIR) $(BINDIR)

# Installation targets
install: all
	cp $(LIBDIR)/* ../../dist/lib/ 2>/dev/null || true
	cp $(BINDIR)/* ../../dist/bin/ 2>/dev/null || true

.PHONY: all test test-unit test-integration clean install
