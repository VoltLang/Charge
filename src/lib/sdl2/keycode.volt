/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
module lib.sdl2.keycode;
extern (C):

/*
 *  \file SDL_keycode.h
 *
 *  Defines constants which identify keyboard keys and modifiers.
 */

import lib.sdl2.stdinc;
public import lib.sdl2.scancode;

/**
 *  \brief The SDL virtual key representation.
 *
 *  Values of this type are used to represent keyboard keys using the current
 *  layout of the keyboard.  These values include Unicode values representing
 *  the unmodified character that would be generated by pressing the key, or
 *  an SDLK_* constant for those keys that do not generate characters.
 */
alias SDL_Keycode = Sint32;

enum SDLK_SCANCODE_MASK = 1<<30;

enum
{
    SDLK_UNKNOWN = 0,
    SDLK_RETURN = '\r',
    SDLK_ESCAPE = 27,
    SDLK_BACKSPACE = '\b',
    SDLK_TAB = '\t',
    SDLK_SPACE = ' ',
    SDLK_EXCLAIM = '!',
    SDLK_QUOTEDBL = '"',
    SDLK_HASH = '#',
    SDLK_PERCENT = '%',
    SDLK_DOLLAR = '$',
    SDLK_AMPERSAND = '&',
    SDLK_QUOTE = '\'',
    SDLK_LEFTPAREN = '(',
    SDLK_RIGHTPAREN = ')',
    SDLK_ASTERISK = '*',
    SDLK_PLUS = '+',
    SDLK_COMMA = ',',
    SDLK_MINUS = '-',
    SDLK_PERIOD = '.',
    SDLK_SLASH = '/',
    SDLK_0 = '0',
    SDLK_1 = '1',
    SDLK_2 = '2',
    SDLK_3 = '3',
    SDLK_4 = '4',
    SDLK_5 = '5',
    SDLK_6 = '6',
    SDLK_7 = '7',
    SDLK_8 = '8',
    SDLK_9 = '9',
    SDLK_COLON = ':',
    SDLK_SEMICOLON = ';',
    SDLK_LESS = '<',
    SDLK_EQUALS = '=',
    SDLK_GREATER = '>',
    SDLK_QUESTION = '?',
    SDLK_AT = '@',
    /*
       Skip uppercase letters
     */
    SDLK_LEFTBRACKET = '[',
    SDLK_BACKSLASH = '\\',
    SDLK_RIGHTBRACKET = ']',
    SDLK_CARET = '^',
    SDLK_UNDERSCORE = '_',
    SDLK_BACKQUOTE = '`',
    SDLK_a = 'a',
    SDLK_b = 'b',
    SDLK_c = 'c',
    SDLK_d = 'd',
    SDLK_e = 'e',
    SDLK_f = 'f',
    SDLK_g = 'g',
    SDLK_h = 'h',
    SDLK_i = 'i',
    SDLK_j = 'j',
    SDLK_k = 'k',
    SDLK_l = 'l',
    SDLK_m = 'm',
    SDLK_n = 'n',
    SDLK_o = 'o',
    SDLK_p = 'p',
    SDLK_q = 'q',
    SDLK_r = 'r',
    SDLK_s = 's',
    SDLK_t = 't',
    SDLK_u = 'u',
    SDLK_v = 'v',
    SDLK_w = 'w',
    SDLK_x = 'x',
    SDLK_y = 'y',
    SDLK_z = 'z',

    SDLK_CAPSLOCK = (SDL_SCANCODE_CAPSLOCK|SDLK_SCANCODE_MASK),

    SDLK_F1 = (SDL_SCANCODE_F1|SDLK_SCANCODE_MASK),
    SDLK_F2 = (SDL_SCANCODE_F2|SDLK_SCANCODE_MASK),
    SDLK_F3 = (SDL_SCANCODE_F3|SDLK_SCANCODE_MASK),
    SDLK_F4 = (SDL_SCANCODE_F4|SDLK_SCANCODE_MASK),
    SDLK_F5 = (SDL_SCANCODE_F5|SDLK_SCANCODE_MASK),
    SDLK_F6 = (SDL_SCANCODE_F6|SDLK_SCANCODE_MASK),
    SDLK_F7 = (SDL_SCANCODE_F7|SDLK_SCANCODE_MASK),
    SDLK_F8 = (SDL_SCANCODE_F8|SDLK_SCANCODE_MASK),
    SDLK_F9 = (SDL_SCANCODE_F9|SDLK_SCANCODE_MASK),
    SDLK_F10 = (SDL_SCANCODE_F10|SDLK_SCANCODE_MASK),
    SDLK_F11 = (SDL_SCANCODE_F11|SDLK_SCANCODE_MASK),
    SDLK_F12 = (SDL_SCANCODE_F12|SDLK_SCANCODE_MASK),

    SDLK_PRINTSCREEN = (SDL_SCANCODE_PRINTSCREEN|SDLK_SCANCODE_MASK),
    SDLK_SCROLLLOCK = (SDL_SCANCODE_SCROLLLOCK|SDLK_SCANCODE_MASK),
    SDLK_PAUSE = (SDL_SCANCODE_PAUSE|SDLK_SCANCODE_MASK),
    SDLK_INSERT = (SDL_SCANCODE_INSERT|SDLK_SCANCODE_MASK),
    SDLK_HOME = (SDL_SCANCODE_HOME|SDLK_SCANCODE_MASK),
    SDLK_PAGEUP = (SDL_SCANCODE_PAGEUP|SDLK_SCANCODE_MASK),
    SDLK_DELETE = 177,
    SDLK_END = (SDL_SCANCODE_END|SDLK_SCANCODE_MASK),
    SDLK_PAGEDOWN = (SDL_SCANCODE_PAGEDOWN|SDLK_SCANCODE_MASK),
    SDLK_RIGHT = (SDL_SCANCODE_RIGHT|SDLK_SCANCODE_MASK),
    SDLK_LEFT = (SDL_SCANCODE_LEFT|SDLK_SCANCODE_MASK),
    SDLK_DOWN = (SDL_SCANCODE_DOWN|SDLK_SCANCODE_MASK),
    SDLK_UP = (SDL_SCANCODE_UP|SDLK_SCANCODE_MASK),

    SDLK_NUMLOCKCLEAR = (SDL_SCANCODE_NUMLOCKCLEAR|SDLK_SCANCODE_MASK),
    SDLK_KP_DIVIDE = (SDL_SCANCODE_KP_DIVIDE|SDLK_SCANCODE_MASK),
    SDLK_KP_MULTIPLY = (SDL_SCANCODE_KP_MULTIPLY|SDLK_SCANCODE_MASK),
    SDLK_KP_MINUS = (SDL_SCANCODE_KP_MINUS|SDLK_SCANCODE_MASK),
    SDLK_KP_PLUS = (SDL_SCANCODE_KP_PLUS|SDLK_SCANCODE_MASK),
    SDLK_KP_ENTER = (SDL_SCANCODE_KP_ENTER|SDLK_SCANCODE_MASK),
    SDLK_KP_1 = (SDL_SCANCODE_KP_1|SDLK_SCANCODE_MASK),
    SDLK_KP_2 = (SDL_SCANCODE_KP_2|SDLK_SCANCODE_MASK),
    SDLK_KP_3 = (SDL_SCANCODE_KP_3|SDLK_SCANCODE_MASK),
    SDLK_KP_4 = (SDL_SCANCODE_KP_4|SDLK_SCANCODE_MASK),
    SDLK_KP_5 = (SDL_SCANCODE_KP_5|SDLK_SCANCODE_MASK),
    SDLK_KP_6 = (SDL_SCANCODE_KP_6|SDLK_SCANCODE_MASK),
    SDLK_KP_7 = (SDL_SCANCODE_KP_7|SDLK_SCANCODE_MASK),
    SDLK_KP_8 = (SDL_SCANCODE_KP_8|SDLK_SCANCODE_MASK),
    SDLK_KP_9 = (SDL_SCANCODE_KP_9|SDLK_SCANCODE_MASK),
    SDLK_KP_0 = (SDL_SCANCODE_KP_0|SDLK_SCANCODE_MASK),
    SDLK_KP_PERIOD = (SDL_SCANCODE_KP_PERIOD|SDLK_SCANCODE_MASK),

    SDLK_APPLICATION = (SDL_SCANCODE_APPLICATION|SDLK_SCANCODE_MASK),
    SDLK_POWER = (SDL_SCANCODE_POWER|SDLK_SCANCODE_MASK),
    SDLK_KP_EQUALS = (SDL_SCANCODE_KP_EQUALS|SDLK_SCANCODE_MASK),
    SDLK_F13 = (SDL_SCANCODE_F13|SDLK_SCANCODE_MASK),
    SDLK_F14 = (SDL_SCANCODE_F14|SDLK_SCANCODE_MASK),
    SDLK_F15 = (SDL_SCANCODE_F15|SDLK_SCANCODE_MASK),
    SDLK_F16 = (SDL_SCANCODE_F16|SDLK_SCANCODE_MASK),
    SDLK_F17 = (SDL_SCANCODE_F17|SDLK_SCANCODE_MASK),
    SDLK_F18 = (SDL_SCANCODE_F18|SDLK_SCANCODE_MASK),
    SDLK_F19 = (SDL_SCANCODE_F19|SDLK_SCANCODE_MASK),
    SDLK_F20 = (SDL_SCANCODE_F20|SDLK_SCANCODE_MASK),
    SDLK_F21 = (SDL_SCANCODE_F21|SDLK_SCANCODE_MASK),
    SDLK_F22 = (SDL_SCANCODE_F22|SDLK_SCANCODE_MASK),
    SDLK_F23 = (SDL_SCANCODE_F23|SDLK_SCANCODE_MASK),
    SDLK_F24 = (SDL_SCANCODE_F24|SDLK_SCANCODE_MASK),
    SDLK_EXECUTE = (SDL_SCANCODE_EXECUTE|SDLK_SCANCODE_MASK),
    SDLK_HELP = (SDL_SCANCODE_HELP|SDLK_SCANCODE_MASK),
    SDLK_MENU = (SDL_SCANCODE_MENU|SDLK_SCANCODE_MASK),
    SDLK_SELECT = (SDL_SCANCODE_SELECT|SDLK_SCANCODE_MASK),
    SDLK_STOP = (SDL_SCANCODE_STOP|SDLK_SCANCODE_MASK),
    SDLK_AGAIN = (SDL_SCANCODE_AGAIN|SDLK_SCANCODE_MASK),
    SDLK_UNDO = (SDL_SCANCODE_UNDO|SDLK_SCANCODE_MASK),
    SDLK_CUT = (SDL_SCANCODE_CUT|SDLK_SCANCODE_MASK),
    SDLK_COPY = (SDL_SCANCODE_COPY|SDLK_SCANCODE_MASK),
    SDLK_PASTE = (SDL_SCANCODE_PASTE|SDLK_SCANCODE_MASK),
    SDLK_FIND = (SDL_SCANCODE_FIND|SDLK_SCANCODE_MASK),
    SDLK_MUTE = (SDL_SCANCODE_MUTE|SDLK_SCANCODE_MASK),
    SDLK_VOLUMEUP = (SDL_SCANCODE_VOLUMEUP|SDLK_SCANCODE_MASK),
    SDLK_VOLUMEDOWN = (SDL_SCANCODE_VOLUMEDOWN|SDLK_SCANCODE_MASK),
    SDLK_KP_COMMA = (SDL_SCANCODE_KP_COMMA|SDLK_SCANCODE_MASK),
    SDLK_KP_EQUALSAS400 =
        (SDL_SCANCODE_KP_EQUALSAS400|SDLK_SCANCODE_MASK),

    SDLK_ALTERASE = (SDL_SCANCODE_ALTERASE|SDLK_SCANCODE_MASK),
    SDLK_SYSREQ = (SDL_SCANCODE_SYSREQ|SDLK_SCANCODE_MASK),
    SDLK_CANCEL = (SDL_SCANCODE_CANCEL|SDLK_SCANCODE_MASK),
    SDLK_CLEAR = (SDL_SCANCODE_CLEAR|SDLK_SCANCODE_MASK),
    SDLK_PRIOR = (SDL_SCANCODE_PRIOR|SDLK_SCANCODE_MASK),
    SDLK_RETURN2 = (SDL_SCANCODE_RETURN2|SDLK_SCANCODE_MASK),
    SDLK_SEPARATOR = (SDL_SCANCODE_SEPARATOR|SDLK_SCANCODE_MASK),
    SDLK_OUT = (SDL_SCANCODE_OUT|SDLK_SCANCODE_MASK),
    SDLK_OPER = (SDL_SCANCODE_OPER|SDLK_SCANCODE_MASK),
    SDLK_CLEARAGAIN = (SDL_SCANCODE_CLEARAGAIN|SDLK_SCANCODE_MASK),
    SDLK_CRSEL = (SDL_SCANCODE_CRSEL|SDLK_SCANCODE_MASK),
    SDLK_EXSEL = (SDL_SCANCODE_EXSEL|SDLK_SCANCODE_MASK),

    SDLK_KP_00 = (SDL_SCANCODE_KP_00|SDLK_SCANCODE_MASK),
    SDLK_KP_000 = (SDL_SCANCODE_KP_000|SDLK_SCANCODE_MASK),
    SDLK_THOUSANDSSEPARATOR =
        (SDL_SCANCODE_THOUSANDSSEPARATOR|SDLK_SCANCODE_MASK),
    SDLK_DECIMALSEPARATOR =
        (SDL_SCANCODE_DECIMALSEPARATOR|SDLK_SCANCODE_MASK),
    SDLK_CURRENCYUNIT = (SDL_SCANCODE_CURRENCYUNIT|SDLK_SCANCODE_MASK),
    SDLK_CURRENCYSUBUNIT =
        (SDL_SCANCODE_CURRENCYSUBUNIT|SDLK_SCANCODE_MASK),
    SDLK_KP_LEFTPAREN = (SDL_SCANCODE_KP_LEFTPAREN|SDLK_SCANCODE_MASK),
    SDLK_KP_RIGHTPAREN = (SDL_SCANCODE_KP_RIGHTPAREN|SDLK_SCANCODE_MASK),
    SDLK_KP_LEFTBRACE = (SDL_SCANCODE_KP_LEFTBRACE|SDLK_SCANCODE_MASK),
    SDLK_KP_RIGHTBRACE = (SDL_SCANCODE_KP_RIGHTBRACE|SDLK_SCANCODE_MASK),
    SDLK_KP_TAB = (SDL_SCANCODE_KP_TAB|SDLK_SCANCODE_MASK),
    SDLK_KP_BACKSPACE = (SDL_SCANCODE_KP_BACKSPACE|SDLK_SCANCODE_MASK),
    SDLK_KP_A = (SDL_SCANCODE_KP_A|SDLK_SCANCODE_MASK),
    SDLK_KP_B = (SDL_SCANCODE_KP_B|SDLK_SCANCODE_MASK),
    SDLK_KP_C = (SDL_SCANCODE_KP_C|SDLK_SCANCODE_MASK),
    SDLK_KP_D = (SDL_SCANCODE_KP_D|SDLK_SCANCODE_MASK),
    SDLK_KP_E = (SDL_SCANCODE_KP_E|SDLK_SCANCODE_MASK),
    SDLK_KP_F = (SDL_SCANCODE_KP_F|SDLK_SCANCODE_MASK),
    SDLK_KP_XOR = (SDL_SCANCODE_KP_XOR|SDLK_SCANCODE_MASK),
    SDLK_KP_POWER = (SDL_SCANCODE_KP_POWER|SDLK_SCANCODE_MASK),
    SDLK_KP_PERCENT = (SDL_SCANCODE_KP_PERCENT|SDLK_SCANCODE_MASK),
    SDLK_KP_LESS = (SDL_SCANCODE_KP_LESS|SDLK_SCANCODE_MASK),
    SDLK_KP_GREATER = (SDL_SCANCODE_KP_GREATER|SDLK_SCANCODE_MASK),
    SDLK_KP_AMPERSAND = (SDL_SCANCODE_KP_AMPERSAND|SDLK_SCANCODE_MASK),
    SDLK_KP_DBLAMPERSAND =
        (SDL_SCANCODE_KP_DBLAMPERSAND|SDLK_SCANCODE_MASK),
    SDLK_KP_VERTICALBAR =
        (SDL_SCANCODE_KP_VERTICALBAR|SDLK_SCANCODE_MASK),
    SDLK_KP_DBLVERTICALBAR =
        (SDL_SCANCODE_KP_DBLVERTICALBAR|SDLK_SCANCODE_MASK),
    SDLK_KP_COLON = (SDL_SCANCODE_KP_COLON|SDLK_SCANCODE_MASK),
    SDLK_KP_HASH = (SDL_SCANCODE_KP_HASH|SDLK_SCANCODE_MASK),
    SDLK_KP_SPACE = (SDL_SCANCODE_KP_SPACE|SDLK_SCANCODE_MASK),
    SDLK_KP_AT = (SDL_SCANCODE_KP_AT|SDLK_SCANCODE_MASK),
    SDLK_KP_EXCLAM = (SDL_SCANCODE_KP_EXCLAM|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMSTORE = (SDL_SCANCODE_KP_MEMSTORE|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMRECALL = (SDL_SCANCODE_KP_MEMRECALL|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMCLEAR = (SDL_SCANCODE_KP_MEMCLEAR|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMADD = (SDL_SCANCODE_KP_MEMADD|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMSUBTRACT =
        (SDL_SCANCODE_KP_MEMSUBTRACT|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMMULTIPLY =
        (SDL_SCANCODE_KP_MEMMULTIPLY|SDLK_SCANCODE_MASK),
    SDLK_KP_MEMDIVIDE = (SDL_SCANCODE_KP_MEMDIVIDE|SDLK_SCANCODE_MASK),
    SDLK_KP_PLUSMINUS = (SDL_SCANCODE_KP_PLUSMINUS|SDLK_SCANCODE_MASK),
    SDLK_KP_CLEAR = (SDL_SCANCODE_KP_CLEAR|SDLK_SCANCODE_MASK),
    SDLK_KP_CLEARENTRY = (SDL_SCANCODE_KP_CLEARENTRY|SDLK_SCANCODE_MASK),
    SDLK_KP_BINARY = (SDL_SCANCODE_KP_BINARY|SDLK_SCANCODE_MASK),
    SDLK_KP_OCTAL = (SDL_SCANCODE_KP_OCTAL|SDLK_SCANCODE_MASK),
    SDLK_KP_DECIMAL = (SDL_SCANCODE_KP_DECIMAL|SDLK_SCANCODE_MASK),
    SDLK_KP_HEXADECIMAL =
        (SDL_SCANCODE_KP_HEXADECIMAL|SDLK_SCANCODE_MASK),

    SDLK_LCTRL = (SDL_SCANCODE_LCTRL|SDLK_SCANCODE_MASK),
    SDLK_LSHIFT = (SDL_SCANCODE_LSHIFT|SDLK_SCANCODE_MASK),
    SDLK_LALT = (SDL_SCANCODE_LALT|SDLK_SCANCODE_MASK),
    SDLK_LGUI = (SDL_SCANCODE_LGUI|SDLK_SCANCODE_MASK),
    SDLK_RCTRL = (SDL_SCANCODE_RCTRL|SDLK_SCANCODE_MASK),
    SDLK_RSHIFT = (SDL_SCANCODE_RSHIFT|SDLK_SCANCODE_MASK),
    SDLK_RALT = (SDL_SCANCODE_RALT|SDLK_SCANCODE_MASK),
    SDLK_RGUI = (SDL_SCANCODE_RGUI|SDLK_SCANCODE_MASK),

    SDLK_MODE = (SDL_SCANCODE_MODE|SDLK_SCANCODE_MASK),

    SDLK_AUDIONEXT = (SDL_SCANCODE_AUDIONEXT|SDLK_SCANCODE_MASK),
    SDLK_AUDIOPREV = (SDL_SCANCODE_AUDIOPREV|SDLK_SCANCODE_MASK),
    SDLK_AUDIOSTOP = (SDL_SCANCODE_AUDIOSTOP|SDLK_SCANCODE_MASK),
    SDLK_AUDIOPLAY = (SDL_SCANCODE_AUDIOPLAY|SDLK_SCANCODE_MASK),
    SDLK_AUDIOMUTE = (SDL_SCANCODE_AUDIOMUTE|SDLK_SCANCODE_MASK),
    SDLK_MEDIASELECT = (SDL_SCANCODE_MEDIASELECT|SDLK_SCANCODE_MASK),
    SDLK_WWW = (SDL_SCANCODE_WWW|SDLK_SCANCODE_MASK),
    SDLK_MAIL = (SDL_SCANCODE_MAIL|SDLK_SCANCODE_MASK),
    SDLK_CALCULATOR = (SDL_SCANCODE_CALCULATOR|SDLK_SCANCODE_MASK),
    SDLK_COMPUTER = (SDL_SCANCODE_COMPUTER|SDLK_SCANCODE_MASK),
    SDLK_AC_SEARCH = (SDL_SCANCODE_AC_SEARCH|SDLK_SCANCODE_MASK),
    SDLK_AC_HOME = (SDL_SCANCODE_AC_HOME|SDLK_SCANCODE_MASK),
    SDLK_AC_BACK = (SDL_SCANCODE_AC_BACK|SDLK_SCANCODE_MASK),
    SDLK_AC_FORWARD = (SDL_SCANCODE_AC_FORWARD|SDLK_SCANCODE_MASK),
    SDLK_AC_STOP = (SDL_SCANCODE_AC_STOP|SDLK_SCANCODE_MASK),
    SDLK_AC_REFRESH = (SDL_SCANCODE_AC_REFRESH|SDLK_SCANCODE_MASK),
    SDLK_AC_BOOKMARKS = (SDL_SCANCODE_AC_BOOKMARKS|SDLK_SCANCODE_MASK),

    SDLK_BRIGHTNESSDOWN =
        (SDL_SCANCODE_BRIGHTNESSDOWN|SDLK_SCANCODE_MASK),
    SDLK_BRIGHTNESSUP = (SDL_SCANCODE_BRIGHTNESSUP|SDLK_SCANCODE_MASK),
    SDLK_DISPLAYSWITCH = (SDL_SCANCODE_DISPLAYSWITCH|SDLK_SCANCODE_MASK),
    SDLK_KBDILLUMTOGGLE =
        (SDL_SCANCODE_KBDILLUMTOGGLE|SDLK_SCANCODE_MASK),
    SDLK_KBDILLUMDOWN = (SDL_SCANCODE_KBDILLUMDOWN|SDLK_SCANCODE_MASK),
    SDLK_KBDILLUMUP = (SDL_SCANCODE_KBDILLUMUP|SDLK_SCANCODE_MASK),
    SDLK_EJECT = (SDL_SCANCODE_EJECT|SDLK_SCANCODE_MASK),
    SDLK_SLEEP = (SDL_SCANCODE_SLEEP|SDLK_SCANCODE_MASK)
}

/**
 * \brief Enumeration of valid key mods (possibly OR'd together).
 */
alias SDL_Keymod = int;
enum : SDL_Keymod
{
    KMOD_NONE = 0x0000,
    KMOD_LSHIFT = 0x0001,
    KMOD_RSHIFT = 0x0002,
    KMOD_LCTRL = 0x0040,
    KMOD_RCTRL = 0x0080,
    KMOD_LALT = 0x0100,
    KMOD_RALT = 0x0200,
    KMOD_LGUI = 0x0400,
    KMOD_RGUI = 0x0800,
    KMOD_NUM = 0x1000,
    KMOD_CAPS = 0x2000,
    KMOD_MODE = 0x4000,
    KMOD_RESERVED = 0x8000
}

enum KMOD_CTRL = (KMOD_LCTRL|KMOD_RCTRL);
enum KMOD_SHIFT = (KMOD_LSHIFT|KMOD_RSHIFT);
enum KMOD_ALT = (KMOD_LALT|KMOD_RALT);
enum KMOD_GUI = (KMOD_LGUI|KMOD_RGUI);

