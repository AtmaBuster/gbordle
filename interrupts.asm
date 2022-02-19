VBlank::
	call VBlank_CopyTilemap
	call VBlank_CopyAttrmap
	call Joypad
	call Random
	ld hl, hBGMapSection
	ld a, [hl]
	inc a
	cp NUM_BGMAP_SECTIONS
	jr c, .set_new_bg_map_section
	xor a
.set_new_bg_map_section
	ld [hl], a
	xor a
	ldh [rSCX], a
	ldh [rSCY], a
	call hTransferVirtualOAM
	ld a, 1
	ldh [hVBlank], a
	pop hl
	pop de
	pop bc
	pop af
	reti

VBlank_CopyTilemap:
	xor a
	ldh [rVBK], a
	ld bc, wTilemap
	jr VBlank_CopyTileAttrmap

VBlank_CopyAttrmap:
	ldh a, [hCGB]
	and a
	ret z
	ld a, 1
	ldh [rVBK], a
	ld bc, wAttrmap
	jr VBlank_CopyTileAttrmap

VBlank_SectionAddrs:
FOR I, NUM_BGMAP_SECTIONS
	dw (I * (SCREEN_HEIGHT / NUM_BGMAP_SECTIONS)) * BG_MAP_WIDTH + $9800
	dw I * SCREEN_WIDTH * (SCREEN_HEIGHT / NUM_BGMAP_SECTIONS)
ENDR

VBlank_CopyTileAttrmap:
	ld [hSPStore], sp
	ldh a, [hBGMapSection]
	add a
	add a
	push bc
	ld c, a
	ld b, 0
	ld hl, VBlank_SectionAddrs
	add hl, bc
	pop bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld sp, hl
	ld h, d
	ld l, e
REPT SCREEN_HEIGHT / 3
REPT SCREEN_WIDTH / 2
	pop de
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
ENDR
	ld bc, $20 - SCREEN_WIDTH
	add hl, bc
ENDR
	ldh a, [hSPStore]
	ld l, a
	ldh a, [hSPStore + 1]
	ld h, a
	ld sp, hl
	ret

LCD::
	ld a, [wGameState]
	cp GAME_STATE_START
	jr c, .done
	ldh a, [rLY]
	cp 112
	jr c, .s0
	cp 124
	jr c, .s1
	cp 132
	jr c, .s2
	jr nc, .s3
.s0
	xor a
	ldh [rSCX], a
	ldh [rSCY], a
	jr .done

.s1
	ld a, 4
	ldh [rSCX], a
	ldh [rSCY], a
	jr .done

.s2
	xor a
	ldh [rSCX], a
	ld a, 4
	ldh [rSCY], a
	jr .done

.s3
	ld a, -4
	ldh [rSCX], a
	ld a, 4
	ldh [rSCY], a
	jr .done

.done
	pop af
	reti

Joypad::
	ld a, R_DPAD
	ldh [rJOYP], a
; read twice, for stability
	ldh a, [rJOYP]
	ldh a, [rJOYP]

	cpl
	and $f
	swap a
	ld b, a

	ld a, R_BUTTONS
	ldh [rJOYP], a
; read a few times, for stability
rept 6
	ldh a, [rJOYP]
endr
	cpl
	and $f
	or b
	ld b, a

; reset joy register
	ld a, $30
	ldh [rJOYP], a

; get useful joy info
	ldh a, [hJoyPressed]
	ld e, a
	xor b
	ld d, a
	and e
	ldh [hJoyUp], a
	ld a, d
	and b
	ldh [hJoyDown], a
	ld a, b
	ldh [hJoyPressed], a
	ret

; https://github.com/edrosten/8bit_rng/blob/master/rng-4261412736.c
Random::
	ldh a, [hRandomX]
	ld b, a
	add a
	add a
	xor b
	ld b, a
	ldh a, [hRandomY]
	ldh [hRandomX], a
	ldh a, [hRandomZ]
	ldh [hRandomY], a
	ldh a, [hRandomA]
	ldh [hRandomZ], a
	ld c, a
	xor b
	ld d, a
	ld a, b
	add a
	xor d
	ld b, a
	ld a, c
	srl a
	xor b
	ldh [hRandomA], a
	ret
