# Makefile for windows.
# Intended for Digital Mars Make and GNU Make.

VOLT = volt
VFLAGS = -d
LDFLAGS = -l SDL.lib
TARGET = Charge.exe
include sources.mk

all: $(TARGET)

$(TARGET):
	$(VOLT) $(VFLAGS) $(LDFLAGS) -o $(TARGET) -I src $(SRC)

clean:
	del /q $(TARGET)

.PHONY: all clean
