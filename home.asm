INCLUDE "constants.asm"

SECTION "RST0", ROM0[$0000]
rst0::
	ret

SECTION "RST8", ROM0[$0008]
Bankswitch::
	ld [MBC5RomBank], a
	ret

SECTION "RST10", ROM0[$0010]
rst10::
	ret

SECTION "RST18", ROM0[$0018]
rst18::
	ret

SECTION "RST20", ROM0[$0020]
rst20::
	ret

SECTION "RST28", ROM0[$0028]
rst28::
	ret

SECTION "RST30", ROM0[$0030]
rst30::
	ret

SECTION "RST38", ROM0[$0038]
rst38::
	ret

SECTION "Interrupt", ROM0[$0040]
_VBlank::
	push af
	push bc
	push de
	push hl
	jp VBlank

	ds $48 - @
_LCD::
	push af
	jp LCD

	ds $50 - @
_Timer::
	reti

	ds $58 - @
_Serial::
	reti

	ds $60 - @
_Joypad::
	reti

SECTION "Start", ROM0[$0100]
Start::
	nop
	jp _Start

	ds $150 - @
_Start::
	cp $11
	jr z, .cgb
	ld a, c
	cp $14
	jr z, .sgb
	xor a
	ldh [hCGB], a
	ldh [hSGB], a
	jr .done_hw_detect

.sgb
	ld a, 1
	ldh [hSGB], a
	xor a
	ldh [hCGB], a
	jr .done_hw_detect

.cgb
	ld a, 1
	ldh [hCGB], a
	xor a
	ldh [hSGB], a
.done_hw_detect
; disable lcd
	call DisableLCD
; clear wram
	ld hl, $c000
	ld bc, $2000
	xor a
.clear_loop
	ld [hli], a
	dec c
	jr nz, .clear_loop
	dec b
	jr nz, .clear_loop
; init stack pointer
	ld sp, wStackBottom
; clear hram
	ld hl, $ff82
	ld bc, $007d
	xor a
	call ByteFill

	call ClearDMGSGBColors

	ld hl, rLCDC
	res rLCDC_TILE_DATA, [hl]
	set rLCDC_SPRITE_SIZE, [hl]
	set rLCDC_SPRITES_ENABLE, [hl]

	call WriteOAMDMACode

	call InitColorData
	call InitGraphics

; set double speed mode
	call SetDoubleSpeed

; enable vblank interrupt
	xor a
	ldh [rIF], a
	ld a, (1 << VBLANK) | (1 << LCD_STAT)
	ldh [rIE], a
	ld hl, rSTAT
	set 3, [hl]
	ld a, 104
	ldh [rLYC], a
	ei

; init RNG
	ld a, 1
	ldh [hRandomA], a

	jp GameLoop

.not_cgb_spin:
	stop
	jr .not_cgb_spin

WriteOAMDMACode::
	ld c, LOW(hTransferVirtualOAM)
	ld b, OAMDMACodeEnd - OAMDMACode
	ld hl, OAMDMACode
.copy
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copy
	ret

OAMDMACode:
LOAD "OAM DMA", HRAM
hTransferVirtualOAM::
	ld a, HIGH(wVirtualOAM)
	ldh [rDMA], a
	ld a, 40
.wait
	dec a
	jr nz, .wait
	ret
ENDL
OAMDMACodeEnd:

SetDoubleSpeed:
	ldh a, [hCGB]
	and a
	ret z
	ld hl, rKEY1
	set 0, [hl]
	xor a
	ldh [rIF], a
	ldh [rIE], a
	ld a, $30
	ldh [rJOYP], a
	stop
	ret

EnableLCD::
	ldh a, [rLCDC]
	bit rLCDC_ENABLE, a
	ret nz
	set rLCDC_ENABLE, a
	ldh [rLCDC], a
	ret

DisableLCD::
; do nothing if already disabled
	ldh a, [rLCDC]
	bit rLCDC_ENABLE, a
	ret z
; wait for vblank
	di
.loop
	ldh a, [rLY]
	cp $90
	jr c, .loop
	ldh a, [rLCDC]
	res rLCDC_ENABLE, a
	ldh [rLCDC], a
	reti

InitColorData:
; init bg pals
	ld c, LOW(rBGPI)
	ld hl, .BGPalData
	call .do_pals
; init ob pals
	ld c, LOW(rOBPI)
.do_pals
	ld a, (1 << rBGPI_AUTO_INCREMENT)
	ldh [c], a
	ld b, 64
	inc c
.col_loop
	ld a, [hli]
	ldh [c], a
	dec b
	jr nz, .col_loop
	ret

.BGPalData:
	RGB 31,31,31, 31,31,31, 21,21,21, 00,00,00
	RGB 31,31,31, 11,22,15, 08,15,11, 31,31,31
	RGB 31,31,31, 29,25,00, 22,19,00, 31,31,31
	RGB 31,31,31, 20,20,20, 10,10,10, 31,31,31
	RGB 31,31,31, 31,15,18, 31,00,08, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
.OBPalData:
	RGB 31,31,31, 31,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00
	RGB 00,00,00, 00,00,00, 00,00,00, 00,00,00

CopyBytes::
	inc b
	inc c
	jr .handle_loop
.copy_byte
	ld a, [hli]
	ld [de], a
	inc de
.handle_loop
	dec c
	jr nz, .copy_byte
	dec b
	jr nz, .copy_byte
	ret

ByteFill::
	inc b
	inc c
	jr .handle_loop
.put_byte
	ld [hli], a
.handle_loop
	dec c
	jr nz, .put_byte
	dec b
	jr nz, .put_byte
	ret

DelayFrame:
	xor a
	ldh [hVBlank], a
.loop
	halt
	nop
	ldh a, [hVBlank]
	and a
	jr z, .loop
	ret

CopyWord::
; copies a word from a:hl to de
	rst Bankswitch
	push bc
	ld bc, 6
	call CopyBytes
	pop bc
	ret

MulHL_A:
	push bc
	ld b, h
	ld c, l
	ld hl, 0
	and a
	jr z, .done
.loop
	add hl, bc
	dec a
	jr nz, .loop
.done
	pop bc
	ret

PlaceBigLetter:
; a    = letter to place (1=A, 2=B, etc.)
; b, c = x, y
; d    = color
	push af
	call .do_palette
	pop af
	call BCtoMapOffset
	ld hl, wTilemap
	add hl, bc
	dec a
	add a
	add a
	add $80
	ld [hli], a
	inc a
	ld [hl], a
	inc a
	ld de, SCREEN_WIDTH - 1
	add hl, de
	ld [hli], a
	inc a
	ld [hl], a
	ret

.do_palette
	ldh a, [hCGB]
	and a
	jr nz, .cgb
	ldh a, [hSGB]
	and a
	ret z ; DMG
; sgb
	call InitWRAMBlkPacket
	ld a, b
	ld [wSGBAttrPacketBuffer + 4], a
	inc a
	ld [wSGBAttrPacketBuffer + 6], a
	ld a, c
	ld [wSGBAttrPacketBuffer + 5], a
	inc a
	ld [wSGBAttrPacketBuffer + 7], a
	ld a, d
	add a
	add a
	or d
	ld [wSGBAttrPacketBuffer + 3], a
	ld hl, wSGBAttrPacketBuffer
	push bc
	call SendSGBPackets
	pop bc
	ret

.cgb
	push bc
	call BCtoMapOffset
	ld hl, wAttrmap
	add hl, bc
	ld a, d
	ld [hli], a
	ld [hl], a
	ld de, SCREEN_WIDTH - 1
	add hl, de
	ld [hli], a
	ld [hl], a
	pop bc
	ret

BCtoMapOffset:
	push af
	push hl
	ld a, c
	ld hl, SCREEN_WIDTH
	call MulHL_A
	ld c, b
	ld b, 0
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	pop af
	ret

PlaceExtraIndicator:
; a    = char to place
; b, c = x, y
; d    = color
	push af
	ld a, c
	ld hl, SCREEN_WIDTH
	call MulHL_A
	ld c, b
	ld b, 0
	add hl, bc
	ld b, h
	ld c, l
	ld hl, wAttrmap
	add hl, bc
	ld [hl], d
	pop af
	ld hl, wTilemap
	add hl, bc
	ld [hli], a
	ret

INCLUDE "interrupts.asm"

GameLoop::
	call .DoGameLoop
	call DelayFrame
	call UpdateInfoDisplay
	jr GameLoop

.DoGameLoop:
; check game state
	ld a, [wGameState]
	and a ; GAME_STATE_INIT_TITLE
	jp z, InitTitleScreen
	dec a ; GAME_STATE_TITLE
	jp z, TitleScreen
	dec a ; GAME_STATE_INIT_CREDITS
	jp z, InitCreditsScreen
	dec a ; GAME_STATE_CREDITS
	jp z, CreditsScreen
	dec a ; GAME_STATE_START
	jp z, .StartGame
	dec a ; GAME_STATE_GUESS
	jr z, .do_input
	dec a ; GAME_STATE_OVER
	jp z, GameOverWait
	xor a
	ld [wGameState], a
	ret

.do_input
	ldh a, [hJoyDown]
	cp SELECT
	jp z, .select
	cp A_BUTTON
	jp z, .a_button
	cp B_BUTTON
	jp z, .b_button
	cp START
	jr z, .start
; just check d-pad
	and $f0
	ret z
	ld b, 0
	cp D_UP
	jp z, .do_dpad
	inc b
	cp D_DOWN
	jp z, .do_dpad
	inc b
	cp D_RIGHT
	jp z, .do_dpad
	inc b
	cp D_LEFT
	jp z, .do_dpad
	ret

.start
; can't enter if word isn't 5 letters
	ld a, [wCurrentGuessPosition]
	cp 5
	jr nz, .not_long_enough
; can't enter if word isn't a real word
	call CheckBufferWordInList
	jr nc, .not_a_word
; check if word is correct
	ld hl, wCurrentGuessBuffer
	ld de, wHiddenWord
	call CheckEqualWords
	jp c, .win
; incorrect, give feedback
	call GiveWordFeedback
	ld a, [wCurrentGuess]
	cp 6
	ret nz
; too many guesses, loss
; show loss string
	hlcoord 4, 0
	ld de, YouLostString
	call PlaceString
; display word
	decoord 11, 0
	ld hl, wHiddenWord
	ld bc, 5
	call CopyBytes
; hide cursor
	xor a
	ld [wVirtualOAM], a
	ld [wVirtualOAM + 1], a
	ld [wVirtualOAM + 4], a
	ld [wVirtualOAM + 5], a
	ld a, GAME_STATE_OVER
	ld [wGameState], a
	ret

.not_long_enough
	ld de, NotLongEnoughString
	hlcoord 2, 0
	call PlaceString
	ld a, 90
	ld [wInfoDisplayTimer], a
	ret

.not_a_word
	ld de, NotAWordString
	hlcoord 2, 0
	call PlaceString
	ld a, 90
	ld [wInfoDisplayTimer], a
	ret

.a_button
	ld a, [wCurrentGuessPosition]
	cp 5
	ret z
	call GetCurrentSelectedLetter
	push af
	ld hl, wCurrentGuessPosition
	ld a, [hl]
	inc [hl]
	ld c, a
	pop af
	ld b, 0
	ld hl, wCurrentGuessBuffer
	add hl, bc
	ld [hl], a
	push af
	ld a, c
	add a
	add 5
	ld b, a
	ld a, [wCurrentGuess]
	add a
	inc a
	ld c, a
	pop af
	ld d, 0
	call PlaceBigLetter
	ret

.b_button
	ld a, [wCurrentGuessPosition]
	and a
	ret z
	dec a
	ld [wCurrentGuessPosition], a
	add a
	add 5
	ld b, a
	ld a, [wCurrentGuess]
	add a
	inc a
	ld c, a
	ld d, 3
	ld a, 27
	call PlaceBigLetter
	ret

.do_dpad
	ld a, [wKeyboardCursorPos]
	add a
	add a
	add b
	ld c, a
	ld b, 0
	ld hl, CursorMovementTable
	add hl, bc
	ld a, [hl]
	ld [wKeyboardCursorPos], a
	call UpdateCursorXY
	ret

.select
	ld a, [wKeyboardMode]
	xor 1
	ld [wKeyboardMode], a
	call DrawKeyboardTilemap
	ret

.StartGame:

; set up main board
	call ResetBoardTilemap
	call DrawKeyboardTilemap

; init cursor
	call UpdateCursorXY

	call GenerateWord
	ld hl, wGameState
	inc [hl]
	ret

.win
; color current guess all green
	ld a, [wCurrentGuess]
	add a
	inc a
	ld hl, SCREEN_WIDTH
	call MulHL_A
	ld bc, 5
	add hl, bc
	ld bc, wAttrmap
	add hl, bc
	push hl
	ld a, 1
	ld bc, 10
	call ByteFill
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	ld bc, 10
	call ByteFill
; set helper icons
	ld a, [wCurrentGuess]
	add a
	add 2
	ld hl, SCREEN_WIDTH
	call MulHL_A
	ld bc, 15
	add hl, bc
	push hl
	ld bc, wAttrmap
	add hl, bc
	ld a, 1
	ld bc, 5
	call ByteFill
	pop hl
	ld bc, wTilemap
	add hl, bc
	ld a, $fd
	ld bc, 5
	call ByteFill
; show win string
	hlcoord 6, 0
	ld de, YouWinString
	call PlaceString
; hide cursor
	xor a
	ld [wVirtualOAM], a
	ld [wVirtualOAM + 1], a
	ld [wVirtualOAM + 4], a
	ld [wVirtualOAM + 5], a
	ld a, GAME_STATE_OVER
	ld [wGameState], a
	ret

GameOverWait:
	ldh a, [hJoyDown]
	cp A_BUTTON
	jr z, .done
	cp B_BUTTON
	ret nz
.done
	ld a, GAME_STATE_START
	ld [wGameState], a
; clear info
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
	xor a
	call ByteFill
; reset board
	call ResetBoardTilemap
; reset guesses
	xor a
	ld [wCurrentGuess], a
	ld [wCurrentGuessPosition], a
; redraw cursor
	call UpdateCursorXY
	ret

CursorMovementTable:
	;   U   D   R   L
	db 19, 10,  1,  9 ; Q - 0
	db 20, 11,  2,  0 ; W - 1
	db 21, 12,  3,  1 ; E - 2
	db 22, 13,  4,  2 ; R - 3
	db 23, 14,  5,  3 ; T - 4
	db 24, 15,  6,  4 ; Y - 5
	db 25, 16,  7,  5 ; U - 6
	db 17, 17,  8,  6 ; I - 7
	db 18, 18,  9,  7 ; O - 8
	db  9,  9,  0,  8 ; P - 9
	db  0, 19, 11, 18 ; A - 10
	db  1, 20, 12, 10 ; S - 11
	db  2, 21, 13, 11 ; D - 12
	db  3, 22, 14, 12 ; F - 13
	db  4, 23, 15, 13 ; G - 14
	db  5, 24, 16, 14 ; H - 15
	db  6, 25, 17, 15 ; J - 16
	db  7,  7, 18, 16 ; K - 17
	db  8,  8, 10, 17 ; L - 18
	db 10,  0, 20, 25 ; Z - 19
	db 11,  1, 21, 19 ; X - 20
	db 12,  2, 22, 20 ; C - 21
	db 13,  3, 23, 21 ; V - 22
	db 14,  4, 24, 22 ; B - 23
	db 15,  5, 25, 23 ; N - 24
	db 16,  6, 19, 24 ; M - 25

GenerateWord:
.loop
	call Random
	and $f
	ld b, a
	call Random
	ld c, a
; make sure it's in range
	ld a, b
	cp HIGH(NUM_VALID_GAME_WORDS)
	jr c, .ok
	jr nz, .loop
	ld a, c
	cp LOW(NUM_VALID_GAME_WORDS)
	jr nc, .loop
.ok
; choose that number word as the current game's word
	ld hl, 0
rept 6
	add hl, bc
endr
	ld bc, ValidGameWords
	add hl, bc
	ld a, BANK(ValidGameWords)
	ld de, wHiddenWord
	call CopyWord
	ret

UpdateCursorXY:
	ld a, [wKeyboardCursorPos]
	add a
	ld c, a
	ld b, 0
	ld hl, .CursorCoords
	add hl, bc
	ld a, [hli]
	ld [wKeyboardCursorOAMX], a
	ld a, [hl]
	ld [wKeyboardCursorOAMY], a
	call PutCursorOAM
	ret

.CursorCoords:
	db  10, 131
	db  26, 131
	db  42, 131
	db  58, 131
	db  74, 131
	db  90, 131
	db 106, 131
	db 122, 131
	db 138, 131
	db 154, 131
	db  14, 139
	db  30, 139
	db  46, 139
	db  62, 139
	db  78, 139
	db  94, 139
	db 110, 139
	db 126, 139
	db 142, 139
	db  18, 147
	db  34, 147
	db  50, 147
	db  66, 147
	db  82, 147
	db  98, 147
	db 114, 147

PutCursorOAM:
	ld hl, .OAMData
	ld a, [wKeyboardCursorOAMX]
	ld b, a
	ld a, [wKeyboardCursorOAMY]
	ld c, a
	ld de, wVirtualOAM
rept 2
	ld a, [hli]
	add c
	ld [de], a
	inc de
	ld a, [hli]
	add b
	ld [de], a
	inc de
rept 2
	ld a, [hli]
	ld [de], a
	inc de
endr
endr
	ret

.OAMData:
	db 0, 0, $00, $00
	db 0, 8, $02, $00

GetCurrentSelectedLetter:
	ld a, [wKeyboardMode]
	and a
	ld hl, QWERTYKeyList
	jr z, .got_keyboard
	ld hl, ABCDEFKeyList
.got_keyboard
	ld a, [wKeyboardCursorPos]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	ret

QWERTYKeyList:
	db "QWERTYUIOP"
	db "ASDFGHJKL"
	db "ZXCVBNM"

ABCDEFKeyList:
	db "ABCDEFGHIJ"
	db "KLMNOPQRS"
	db "TUVWXYZ"

PlaceString:
; places string in de at hl
.loop
	ld a, [de]
	cp "@"
	ret z
	cp " "
	jr nz, .put
	xor a
.put
	ld [hli], a
	inc de
	jr .loop

CheckBufferWordInList:
; load the first letter's bank
	ld a, [wCurrentGuessBuffer]
	dec a
	ld c, a
	ld b, 0
	ld hl, WordLists
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, [hli]
	rst Bankswitch
; get the first table addr
	ld a, [hli]
	ld h, [hl]
	ld l, a
; get the second table addr
	ld a, [wCurrentGuessBuffer + 1]
	dec a
	add a
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
; check the words
	ld a, [hli] ; num words
	ld c, a
.word_loop
	ld de, wCurrentGuessBuffer
	push hl
	call CheckEqualWords
	pop hl
	ret c ; hit
	ld de, 6
	add hl, de
	dec c
	jr nz, .word_loop
	and a ; miss
	ret

CheckEqualWords:
.loop
	ld a, [hli]
	ld b, a
	ld a, [de]
	and a
	jr z, .hit
	inc de
	cp b
	jr z, .loop
; miss
	and a
	ret

.hit
	scf
	ret

WordLists:
	dba GuessWordlist_A
	dba GuessWordlist_B
	dba GuessWordlist_C
	dba GuessWordlist_D
	dba GuessWordlist_E
	dba GuessWordlist_F
	dba GuessWordlist_G
	dba GuessWordlist_H
	dba GuessWordlist_I
	dba GuessWordlist_J
	dba GuessWordlist_K
	dba GuessWordlist_L
	dba GuessWordlist_M
	dba GuessWordlist_N
	dba GuessWordlist_O
	dba GuessWordlist_P
	dba GuessWordlist_Q
	dba GuessWordlist_R
	dba GuessWordlist_S
	dba GuessWordlist_T
	dba GuessWordlist_U
	dba GuessWordlist_V
	dba GuessWordlist_W
	dba GuessWordlist_X
	dba GuessWordlist_Y
	dba GuessWordlist_Z

UpdateInfoDisplay:
	ld a, [wInfoDisplayTimer]
	and a
	ret z
	dec a
	ld [wInfoDisplayTimer], a
	and a
	ret nz
	hlcoord 0, 0
	ld bc, SCREEN_WIDTH
	xor a
	call ByteFill
	ret

GiveWordFeedback:
	call .MarkGray
	call .MarkGreens
	call .CountLetters
	call .MarkYellow

	xor a
	ld [wCurrentGuessPosition], a

	ld hl, wCurrentGuess
	inc [hl]
	ret

.MarkGray:
	ld hl, wCurrentGuessBuffer
	ld c, 0
.gray_loop
	ld a, [hli]
	and a
	ret z
	call .set_gray
	inc c
	jr .gray_loop

.set_gray
	push hl
	push de
	push bc
	push af
	push bc
	ld a, c
	add 15
	ld b, a
	ld a, [wCurrentGuess]
	add a
	add 2
	ld c, a
	ld a, $ff
	ld d, 3
	call PlaceExtraIndicator
	pop bc
	ld a, c
	add a
	add 5
	ld b, a
	ld a, [wCurrentGuess]
	add a
	inc a
	ld c, a
	pop af
	ld d, 3
	call PlaceBigLetter
	pop bc
	pop de
	pop hl
	ret

.MarkGreens:
	ld hl, wMarkedGreenLetters
	ld bc, 5
	xor a
	call ByteFill
	ld hl, wHiddenWord
	ld de, wCurrentGuessBuffer
	ld c, 0
.green_loop
	ld a, [hli]
	and a
; if zero, done
	ret z
	ld b, a
	ld a, [de]
	inc de
	cp b
; if letters are the same, set to green
	call z, .set_green
	inc c
	jr .green_loop

.set_green
	push hl
	push de
	push bc
	push af
	push bc
	ld a, c
	add 15
	ld b, a
	ld a, [wCurrentGuess]
	add a
	add 2
	ld c, a
	ld a, $fd
	ld d, 1
	call PlaceExtraIndicator
	pop bc
	ld b, 0
	ld hl, wMarkedGreenLetters
	add hl, bc
	inc [hl]
	ld a, c
	add a
	add 5
	ld b, a
	ld a, [wCurrentGuess]
	add a
	inc a
	ld c, a
	pop af
	ld d, 1
	call PlaceBigLetter
	pop bc
	pop de
	pop hl
	ret

.CountLetters:
; clear count buffer
	ld hl, wHiddenWordLetterCount
	ld bc, 26
	xor a
	call ByteFill
; count letters
	ld de, wHiddenWord
.count_letter_loop
	ld a, [de]
	and a
	ret z
	inc de
	dec a
	ld c, a
	ld b, 0
	ld hl, wHiddenWordLetterCount
	add hl, bc
	inc [hl]
	jr .count_letter_loop

.MarkYellow:
	ld de, wCurrentGuessBuffer
	ld c, 0
rept 4
	call .yellow_check_letter
	inc c
endr
	call .yellow_check_letter
	ret

.yellow_check_letter
; get letter
	ld a, [de]
	inc de
; check letter
	dec a
	push bc
	ld c, a
	ld b, 0
	ld hl, wHiddenWordLetterCount
	add hl, bc
	ld a, [hl]
	and a
	ld a, c
	pop bc
	ret z
; set to yellow
	dec [hl]
	inc a
; skip if already green
	push af
	push bc
	ld hl, wMarkedGreenLetters
	ld b, 0
	add hl, bc
	ld a, [hl]
	and a
	jr nz, .skip_yellow
	pop bc
	pop af
	push hl
	push de
	push bc
	push af
	push bc
	ld a, c
	add 15
	ld b, a
	ld a, [wCurrentGuess]
	add a
	add 2
	ld c, a
	ld a, $fe
	ld d, 2
	call PlaceExtraIndicator
	pop bc
	ld a, c
	add a
	add 5
	ld b, a
	ld a, [wCurrentGuess]
	add a
	inc a
	ld c, a
	pop af
	ld d, 2
	call PlaceBigLetter
	pop bc
	pop de
	pop hl
	ret

.skip_yellow
	pop bc
	pop af
	ret

InitTitleScreen:
	ld hl, wTilemap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	xor a
	call ByteFill
; load title screen
	hlcoord 0, 2
	ld c, 80 ; 20 x 4
	ld a, $80 ; first tile
.title_tile_loop
	ld [hli], a
	inc a
	dec c
	jr nz, .title_tile_loop
	hlcoord 4, 12
	ld de, TitleStrings.one
	call PlaceString
	hlcoord 8, 17
	ld de, TitleStrings.two
	call PlaceString
	ldh a, [hCGB]
	and a
	jr z, .check_sgb
	hlcoord 0, 2, wAttrmap
	ld bc, 80
	ld a, 4
	call ByteFill
	jr .finish_title

.check_sgb
	ldh a, [hSGB]
	and a
	jr z, .finish_title ; DMG
	call SetupSGB
	ld hl, SGBPacket_Title
	call SendSGBPackets

.finish_title
	call ResetDMGSGBColors
	ld hl, wGameState
	inc [hl]
	ret

TitleScreen:
	ldh a, [hJoyDown]
	cp SELECT
	jr z, .go_to_credits
	cp A_BUTTON
	jr z, .done
	cp START
	ret nz
.done
	ld a, GAME_STATE_START
	ld [wGameState], a
; clear tilemap and attrmap
	ld hl, wTilemap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT * 2
	xor a
	call ByteFill
	call LoadLetterTiles
	ldh a, [hSGB]
	and a
	ret z
	call ClearDMGSGBColors
	ld hl, SGBPacket_Game
	call SendSGBPackets
	call ResetDMGSGBColors
	ret

.go_to_credits
	ld a, GAME_STATE_INIT_CREDITS
	ld [wGameState], a
	ret

InitCreditsScreen:
	ld hl, wTilemap
	ld bc, SCREEN_WIDTH * SCREEN_HEIGHT
	xor a
	call ByteFill

	hlcoord 0, 0
	ld de, CreditsStrings.one ; Programming:
	call PlaceString
	hlcoord 4, 1
	ld de, CreditsStrings.two ; AtmaBuster
	call PlaceString
	hlcoord 0, 3
	ld de, CreditsStrings.three ; Title art:
	call PlaceString
	hlcoord 4, 4
	ld de, CreditsStrings.four ; susieq
	call PlaceString
	hlcoord 1, 6
	ld de, CreditsStrings.five ; twitter.com/
	call PlaceString
	hlcoord 1, 7
	ld de, CreditsStrings.six ; susiesshitart
	call PlaceString
	hlcoord 0, 14
	ld de, CreditsStrings.seven ; Source code:
	call PlaceString
	hlcoord 1, 16
	ld de, CreditsStrings.eight ; github.com/
	call PlaceString
	hlcoord 1, 17
	ld de, CreditsStrings.nine ; AtmaBuster/gbordle
	call PlaceString

	ld hl, wGameState
	inc [hl]
	ret

CreditsScreen:
	ldh a, [hJoyDown]
	and A_BUTTON | B_BUTTON | SELECT | START
	ret z
.done
	ld a, GAME_STATE_INIT_TITLE
	ld [wGameState], a
	ret

NotLongEnoughString:
	db "NOT LONG ENOUGH@"

NotAWordString:
	db "NOT A VALID WORD@"

YouWinString:
	db "YOU WIN@"

YouLostString:
	db "LOSS :@"

TitleStrings:
.one
	db "Press  START@"
.two
	db "Credits: SEL@"

CreditsStrings:
.one
	db "Programming:@"
.two
	db "AtmaBuster@"
.three
	db "Title art:@"
.four
	db "susieq@"
.five
	db "twitter.com/@"
.six
	db "susiesshitart@"
.seven
	db "Source code:@"
.eight
	db "github.com/@"
.nine
	db "AtmaBuster/gbordle@"

SECTION "Graphics", ROM0
Font8x8::     INCBIN "gfx/font8.2bpp"
Font16x16::   INCBIN "gfx/font16.2bpp"
HelpChars::   INCBIN "gfx/helpchars.2bpp"

MainBoardTilemap:: INCBIN "gfx/mainscreen.tilemap"
MainBoardAttrmap:: INCBIN "gfx/mainscreen.attrmap"

QWERTYTilemap::
	db "@Q@W@E@R@T@Y@U@I@O@P"
	db "@A@S@D@F@G@H@J@K@L@@"
	db "@Z@X@C@V@B@N@M@@@@@@"
ABCDEFTilemap::
	db "@A@B@C@D@E@F@G@H@I@J"
	db "@K@L@M@N@O@P@Q@R@S@@"
	db "@T@U@V@W@X@Y@Z@@@@@@"

CursorGFX:: INCBIN "gfx/cursor.2bpp"

TitleTiles::   INCBIN "gfx/title.2bpp"
Title2Tiles::  INCBIN "gfx/title2.2bpp"
TitleTilemap:: INCBIN "gfx/title.tilemap"
TitleAttrmap:: INCBIN "gfx/title.attrmap"

INCLUDE "graphics.asm"
