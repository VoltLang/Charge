########################################
# Find which compilers are installed.
#

VOLT ?= $(shell which volt)
EMCC ?= $(shell which emcc)


########################################
# Basic settings.
#

VFLAGS ?= -D DynamicSDL
LDFLAGS ?=
TARGET ?= charge
TARGET_HTML ?= $(TARGET).html


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
	@$(VOLT) -I src $(VFLAGS) $(LDFLAGS) -o $(TARGET) $(SRC)

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
