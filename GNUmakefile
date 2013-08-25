########################################
# Find which compilers are installed.
#

VOLT ?= $(shell which volt)
EMCC ?= $(shell which emcc)
HOST_UNAME := $(strip $(shell uname))
HOST_MACHINE := $(strip $(shell uname -m))
UNAME ?= $(HOST_UNAME)
MACHINE ?= $(HOST_MACHINE)


########################################
# Basic settings.
#

VFLAGS ?= -I src
LDFLAGS ?= -l SDL
TARGET = charge
TARGET_HTML = charge.html


########################################
# Setting up the source.
#

SRC = $(shell find src -name "*.volt")
OBJ = $(patsubst src/%.volt, $(OBJ_DIR)/%.bc, $(SRC))


########################################
# Targets.
#

all: $(TARGET)

$(TARGET): $(SRC) GNUmakefile
	@echo "  VOLT   $(TARGET)"
	@$(VOLT) $(LDFLAGS) -o $(TARGET) $(SRC)

emscripten:
	@echo "  VOLT   $(TARGET_HTML)"
	@$(VOLT) --platform emscripten --linker $(EMCC) -o $(TARGET_HTML) $(SRC)

run: all
	@./$(TARGET)

debug: all
	@gdb --args ./$(TARGET)

clean:
	@rm -rf $(TARGET) .obj

.PHONY: all run debug clean
