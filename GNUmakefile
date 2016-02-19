########################################
# Find which compilers are installed.
#

VOLT ?= $(shell which volt)
EMCC ?= $(shell which emcc)


########################################
# Basic settings.
#

VFLAGS ?= -d --internal-perf -D DynamicSDL
LDFLAGS ?=
TARGET ?= Charge
TARGET_HTML ?= $(TARGET).html


########################################
# Setting up the source.
#

include sources.mk
SRC:= $(shell ls $(SRC))


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
