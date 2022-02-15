InitGraphics::
	call DisableLCD
	xor a
	ldh [rVBK], a
; load 8x8 letters
	ld hl, Font8x8
	ld de, $9010
	ld bc, 28 * $10
	call CopyBytes
; load 16x16 letters
	ld hl, Font16x16
	ld de, $8800
	ld bc, 27 * $10 * 4
	call CopyBytes
; load cursor
	ld hl, CursorGFX
	ld de, $8000
	ld bc, 4 * $10
	call CopyBytes
; load title
	ld hl, TitleTiles + $10 * 13
	ld de, $91d0
	ld bc, 99 * $10
	call CopyBytes
	ld hl, Title2Tiles
	ld de, $8ec0
	ld bc, 15 * $10
	call CopyBytes
	jp EnableLCD

ResetBoardTilemap::
	ld hl, MainBoardTilemap
	decoord 0, 1
	ld bc, SCREEN_WIDTH * (SCREEN_HEIGHT - 6)
	call CopyBytes
	ld hl, MainBoardAttrmap
	decoord 0, 1, wAttrmap
	ld bc, SCREEN_WIDTH * (SCREEN_HEIGHT - 6)
	jp CopyBytes

DrawKeyboardTilemap::
	ld a, [wKeyboardMode]
	and a
	ld hl, QWERTYTilemap
	jr z, .got_keyboard
	ld hl, ABCDEFTilemap
.got_keyboard
	decoord 0, 15
	ld bc, SCREEN_WIDTH * 3
	jp CopyBytes
