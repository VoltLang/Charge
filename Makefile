# Makefile for windows.
# Intended for Digital Mars Make and GNU Make.

VOLT = volt
SRC = \
	src\lib\sdl\*.volt \
	src\lib\gles\*.volt \
	src\charge\*.volt \
	src\charge\gfx\*.volt \
	src\charge\util\*.volt \
	src\charge\platform\core\*.volt \
	src\main.volt

all: charge.exe

charge:
	$(VOLT) -l SDL.lib -o charge.exe -I src $(SRC)

clean:
	del /q charge.exe

.PHONY: all clean
