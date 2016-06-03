########################################
# Find which compilers are installed.
#

CC ?= $(shell which gcc)
VOLT ?= $(shell which volt)

########################################
# Basic settings.
#

CFLAGS ?= -g
VFLAGS ?= -d --internal-perf -D DynamicSDL
LDFLAGS ?= -lm
TARGET ?= charge


########################################
# Setting up the source.
#

include sources.mk
SRC:= $(shell ls $(SRC))
OBJ = .obj/stb.o


########################################
# Targets.
#

all: $(TARGET)

.obj/stb.o: src/lib/stb/stb.c src/lib/stb/stb_image.h
	@mkdir -p .obj
	@echo "  CC     $@"
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
