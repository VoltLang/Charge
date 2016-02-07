# Makefile for windows.
# Intended for Digital Mars Make and GNU Make.

VOLT = volt
include sources.mk

all: charge.exe

charge.exe:
	$(VOLT) -l SDL.lib -o charge.exe -I src $(SRC)

clean:
	del /q charge.exe

.PHONY: all clean
