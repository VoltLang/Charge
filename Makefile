# Makefile for windows.
# Intended for Digital Mars Make and GNU Make.

VOLT = volt
VFLAGS = -d
LDFLAGS = -l SDL.lib
TARGET = Charge.exe
include sources.mk

all: $(TARGET)

$(TARGET):
	rmdir /s /q .obj
	mkdir .obj
	cl.exe /c src\lib\stb\stb.c /Fo.obj\stb.obj
	$(VOLT) .obj/stb.obj $(VFLAGS) $(LDFLAGS) -o $(TARGET) -I src $(SRC)

clean:
	rmdir /s /q .obj
	del /q $(TARGET)

.PHONY: all clean
