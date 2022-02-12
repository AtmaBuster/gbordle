INCLUDE "constants.asm"

SECTION "Stack", WRAM0[$c100]

wStackTop::
wStack:: ds $100
wStackBottom::

wTilemap:: ds SCREEN_WIDTH * SCREEN_HEIGHT
wAttrmap:: ds SCREEN_WIDTH * SCREEN_HEIGHT

wGameState:: db

wInfoDisplayTimer:: db

wHiddenWord:: ds 6
wCurrentGuess:: db
wCurrentGuessBuffer:: ds 6
wCurrentGuessPosition:: db

wKeyboardCursorPos:: db
wKeyboardMode:: db
wKeyboardCursorOAMY:: db
wKeyboardCursorOAMX:: db

wHiddenWordLetterCount:: ds 26
wMarkedGreenLetters:: ds 5

SECTION "Virtual OAM", WRAM0, ALIGN[8]
wVirtualOAM:: ds 40 * 4

SECTION "HRAM", HRAM[$ff80]
hTempBank:: db
hBGMapSection:: db
hSPStore:: dw
hVBlank:: db
hJoyDown:: db
hJoyUp:: db
hJoyPressed:: db

hRandomX:: db
hRandomY:: db
hRandomZ:: db
hRandomA:: db
