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
