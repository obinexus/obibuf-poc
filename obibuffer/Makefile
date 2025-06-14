# OBIBUF Obibuffer Layer Makefile
# OBINexus Computing - Aegis Framework

CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=c11 -fPIC
INCLUDES = -Iinclude
SRCDIR = src
OBJDIR = obj
LIBDIR = ../dist/lib

# Source files
SOURCES = $(wildcard $(SRCDIR)/core/*.c $(SRCDIR)/utils/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Library name
LIBNAME = libobibuffer.so
STATIC_LIBNAME = libobibuffer.a

# Targets
all: $(LIBDIR)/$(LIBNAME) $(LIBDIR)/$(STATIC_LIBNAME)

$(LIBDIR)/$(LIBNAME): $(OBJECTS) | $(LIBDIR)
	$(CC) -shared -o $@ $(OBJECTS)

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
