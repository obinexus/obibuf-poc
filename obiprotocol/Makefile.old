# OBIBUF Obiprotocol Layer Makefile
# OBINexus Computing - Aegis Framework

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC -DNASA_STD_8739_8
INCLUDES = -Iinclude
SRCDIR = src
OBJDIR = obj
LIBDIR = ../dist/lib

# Source files - wildcard pattern picks up all .c files automatically
SOURCES = $(wildcard $(SRCDIR)/core/*.c $(SRCDIR)/utils/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Library names
LIBNAME = libobiprotocol.so
STATIC_LIBNAME = libobiprotocol.a

# Main targets
all: $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

# Shared library target
$(LIBDIR)/$(LIBNAME): $(OBJECTS) | $(LIBDIR)
	$(CC) -shared -o $@ $(OBJECTS)

# Static library target  
$(LIBDIR)/$(STATIC_LIBNAME): $(OBJECTS) | $(LIBDIR)
	ar rcs $@ $(OBJECTS)

# Object file compilation rule
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Directory creation
$(OBJDIR):
	mkdir -p $(OBJDIR)/core $(OBJDIR)/utils

$(LIBDIR):
	mkdir -p $(LIBDIR)

# Clean target
clean:
	rm -rf $(OBJDIR)
	rm -f $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

# Specific DFA targets (using correct filename)
dfa: $(OBJDIR)/core/obiprotocol_dfa.o

$(OBJDIR)/core/obiprotocol_dfa.o: $(SRCDIR)/core/obiprotocol_dfa.c include/obiprotocol_dfa.h | $(OBJDIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Test targets for DFA
test-dfa: $(LIBDIR)/$(LIBNAME)
	@echo "Running DFA engine tests..."
	cd tests/unit/dfa && ./run_tests.sh

# Installation target for Aegis framework
install: all
	@echo "Installing Obiprotocol libraries to distribution directory..."
	@mkdir -p ../dist/lib ../dist/include
	cp $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME) ../dist/lib/
	cp include/*.h ../dist/include/

# Debugging target to show variables
debug:
	@echo "SOURCES: $(SOURCES)"
	@echo "OBJECTS: $(OBJECTS)"
	@echo "LIBDIR: $(LIBDIR)"

.PHONY: all clean dfa test-dfa install debug