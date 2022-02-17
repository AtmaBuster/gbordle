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
; load circle, triangle, x
	ld hl, HelpChars
	ld de, $8fd0
	ld bc, 3 * $10
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

SendSGBPackets::
	ld a, [hl]
	and $7
	ret z
	ld b, a
	di
.loop
	push bc
	call _SendSGBPacket
	pop bc
	dec b
	jr nz, .loop
	reti

_SendSGBPacket:
	xor a
	ldh [rJOYP], a ; set P14 and P15 low
	ld a, $30
	ldh [rJOYP], a ; set both high

	ld bc, $1008
.loop1
	ld a, [hli]
	ld d, a
	push bc
.loop2
	bit 0, d
	ld a, $20
	jr z, .send_bit
	ld a, $10
.send_bit
	ldh [rJOYP], a
	ld a, $30
	ldh [rJOYP], a
	rr d
	dec c
	jr nz, .loop2
	pop bc
	dec b
	jr nz, .loop1
	ld a, $20
	ldh [rJOYP], a
	ld a, $30
	ldh [rJOYP], a
	ret

attr_blk_data: MACRO
	db \1
	db \2 + (\3 << 2) + (\4 << 4)
	db \5, \6, \7, \8
ENDM

SGBPacket_Detect1:
	db $89, $01, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

SGBPacket_Detect2:
	db $89, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

SGBPacket_InitCols:
	db $01, $FF, $7F, $FF, $7F, $B5, $56, $00
	db $00, $CB, $3E, $E8, $2D, $FF, $7F, $00
	db $09, $FF, $7F, $3D, $03, $76, $02, $FF
	db $7F, $94, $52, $4A, $29, $FF, $7F, $00

SGBPacket_Title:
	db $21, $01
	attr_blk_data %111, 1,1,2, 00,00, 19,07
	ds 8, 0

SGBPacket_Game:
	db $21, $02
	attr_blk_data %011, 0,0,0, 00,00, 19,17
	attr_blk_data %011, 3,3,0, 05,01, 14,12
	ds 2, 0

SGBPacket_SetMask:
	db $b9, $01, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

SGBPacket_DisableMask:
	db $b9, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

SGBPacket_PalTrn:
	db $59
	ds 15

SetupSGB:
	ld hl, SGBPacket_SetMask
	call SendSGBPackets
	ld hl, SGBPacket_PalTrn
	call SendSGBPackets
	ld hl, SGBPacket_InitCols
	call SendSGBPackets
	ld hl, SGBPacket_InitCols + $10
	call SendSGBPackets
	ld hl, SGBPacket_DisableMask
	call SendSGBPackets
	ret

ClearDMGSGBColors::
	xor a
	ldh [rBGP], a
	ldh [rOBP0], a
	ldh [rOBP1], a
	ret

ResetDMGSGBColors::
	ld a, %11100100
	ldh [rBGP], a
	ld a, %10101010
	ldh [rOBP0], a
	ldh [rOBP1], a
	ret

InitWRAMBlkPacket::
	push bc
	push de
	push hl
	ld hl, .BlkPacket
	ld de, wSGBAttrPacketBuffer
	ld bc, 16
	call CopyBytes
	pop hl
	pop de
	pop bc
	ret

.BlkPacket:
	db $21, $01
	attr_blk_data %010, 0,0,0, 00,00, 00,00
	ds 8, 0
