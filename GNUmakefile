########################################
# Find which compilers are installed.
#

CC ?= $(shell which gcc)
VOLT ?= $(shell which volt)
SDL2_CONFIG ?= $(shell which sdl2-config)


########################################
# Basic settings.
#

BUILD_DIR ?= make
CFLAGS ?= -g
VFLAGS ?= -d --internal-perf
LDFLAGS ?= -lm $(shell $(SDL2_CONFIG) --libs)
TARGET ?= charge


########################################
# Setting up the source.
#

include sources.mk
SRC:= $(shell ls $(SRC))
STB = .obj/$(BUILD_DIR)/stb.o
OBJ = $(STB)


########################################
# Targets.
#

all: $(TARGET)

$(STB): src/lib/stb/stb.c src/lib/stb/stb_image.h
	@echo "  CC     $@"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) src/lib/stb/stb.c -c -o $@

$(TARGET): $(OBJ) $(SRC) GNUmakefile
	@echo "  VOLT   $@"
	@$(VOLT) -I src $(VFLAGS) $(LDFLAGS) -o $(TARGET) $(SRC) $(OBJ)

run: all
	@./$(TARGET)

debug: all
	@gdb --args ./$(TARGET)

clean:
	@rm -rf $(TARGET) .obj

.PHONY: all run debug clean
