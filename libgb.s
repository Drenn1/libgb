.include "libgb/memorymap.s"
.include "libgb/variables.s"
.include "libgb/defines.s"
.include "libgb/macros.s"

.BANK 0

.SECTION "libgb" FREE

readInput:
	push bc
	push hl
	ld hl,hButtonsPressed
	ld a,%00100000 ; get dpad
	ldh [R_P1],a
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	xor $ff
	and $0f
	swap a
	ld b,a

	ld a,%00010000 ; get buttons
	ldh [R_P1],a
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	ldh a,[R_P1]
	xor $ff
	and $0f
	or b

	ld b,[hl]
	ld [hl],a
	ld c,a
	xor b
	and c
	ldh [<hButtonsJustPressed],a
	ld a,c
	xor b
	and b
	ldh [<hButtonsJustReleased],a

	; Calculate autofire

	xor a
	ldh [<hButtonsPressedAutofire],a

	ld hl,hAutofireCounter
	ldh a,[<hButtonsJustPressed]
	or a
	jr z,+
	; Reset autofire
	ld a,AUTOFIRE_START_DELAY
	ld [hl],a
	ldh a,[<hButtonsJustPressed]
	ldh [<hButtonsPressedAutofire],a
+
	dec [hl]
	jr nz,+
	ld a,AUTOFIRE_INTERVAL
	ld [hl],a
	ldh a,[<hButtonsPressed]
	ldh [<hButtonsPressedAutofire],a
+
	pop hl
	pop bc
	ret

disableLcd:
	; Check if already disabled
	ldh a,[R_LCDC]
	and $80
	ret z

	; Wait for vblank
	di
-
	ldh a,[R_LY]
	cp $90
	jr nz,-

	; Disable LCD
	ldh a,[R_LCDC]
	and $7f
	ldh [R_LCDC],a

	ei
	ret

enableLcd:
	ldh a,[R_LCDC]
	or $80
	ldh [R_LCDC],a
	ret

; Clears wram and hram.
; This will nuke the stack. It will return to the caller, but any pops or returns after
; this will fail.
clearMemory:
	pop de ; Get return address (we're about to nuke the stack)

	; Clear $c000-$dfff
	ld hl,$c000
	ld bc,$2000
-
	xor a
	ldi [hl],a
	dec bc
	ld a,b
	or c
	jr nz,-

; zero page
	ld hl,$ff80
	ld b,$7f
	xor a
-
	ldi [hl],a
	dec b
	jr nz,-

	; Return
	ld h,d
	ld l,e
	jp hl

; Assumes lcd is off.
clearVram:
	push bc
	push hl
	ld hl,$8000
	ld bc,$2000
-
	xor a
	ldi [hl],a
	dec bc
	ld a,b
	or c
	jr nz,-
	pop hl
	pop bc
	ret

; Copies bc bytes from hl to de.
copyMemory:
	ldi a,[hl]
	ld [de],a
	inc de
	dec bc
	ld a,b
	or c
	jr nz,copyMemory
	ret

; Fills bc bytes with value of a starting from hl.
fillMemory:
	push de
	ld d,a
-
	ld [hl],d
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,-
	pop de
	ret

fillMemory16:
; =======================================================================================
; Fills a multiple of 16 bytes of memory. Much faster than "fillMemory".
; Parameters: b = number of 16-byte blocks to copy
;             a = value to fill
;             hl = destination
; =======================================================================================
.rept 16
	ldi [hl],a
.endr
	dec b
	jr nz,fillMemory16
	ret

copyMemory16:
; =======================================================================================
; Copies a multiple of 16 bytes of memory. Much faster than "copyMemory".
; Parameters: b = number of 16-byte blocks to copy
;             hl = source
;             de = destination
; =======================================================================================
.rept 16
	ldi a,[hl]
	ld [de],a
	inc de
.endr
	dec b
	jr nz,copyMemory16
	ret

jpbc:
	ld h,b
	ld l,c
	jr jphl
jpde:
	ld h,d
	ld l,e
jphl:
	jp hl

setCpuSpeed_1x:
	ldh a, [R_KEY1]
	rlca
	ret nc 	 ;mode was already 1x.
	jr +

setCpuSpeed_2x:
	ldh a,[R_KEY1]
	rlca
	ret c 	 ;mode was already 2x.

+
	di

	ldh a,[R_IE]
	push af

	xor a
	ldh [R_IE],a
	ldh [R_IF],a
	ld a,$30
	ldh [R_P1],a
	ld a,%00000001
	ldh [R_KEY1],a

	stop
	nop

	pop af
	ldh [R_IE],a

	ei
	ret

; hl = input data (8x4x2 bytes)
loadBgPalettes:
	ld b, %10000000
	ld c, 8

-
	ld a, b
	ldh [$68], a 	;$68 = bcps.

	ldi a, [hl]
	ldh [$69], a 	;$69 = bcpd.
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a
	ldi a, [hl]
	ldh [$69], a

	ld a, b
	add %00001000 	;next palette.
	ld b, a
	dec c
	jr nz, -
	ret


; hl = input data (8x4x2 bytes)
loadObjPalettes:
	ld b, %10000000
	ld c, 8

-
	ld a, b
	ldh [$6A], a 	;$6A = ocps.

	ldi a, [hl]
	ldh [$6B], a 	;$6B = ocpd.
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a
	ldi a, [hl]
	ldh [$6B], a

	ld a, b
	add %00001000 	;next palette.
	ld b, a
	dec c
	jr nz, -
	ret

.include "libgb/math.s"

.ENDS
