INCLUDE "bugsite.inc"

SECTION "Item description double buffer", ROMX[$6700], BANK[$3]
; Compose into the opposite VRAM tile bank. The game draws the next description
; into tilemap 0 while tilemap 1 still displays the previous page.
MobileMenu_DescStage::
    push af
    push bc
    push de
    push hl
    ldh a, [REG_SVBK]
    push af
    ldh a, [REG_VBK]
    push af

    ld a, 1
    ldh [REG_VBK], a
.waitAttr
    ldh a, [REG_STAT]
    and 3
    cp 3
    jr z, .waitAttr
    ld a, [$9D41] ;First description tile's currently displayed bank.
    and 8
    xor 8
    rrca
    rrca
    rrca
    ld e, a

    ld a, BANK(W_WindowManager_CompositionState)
    ldh [REG_SVBK], a
    ld a, e
    ld [W_WindowManager_VWFRingStart + 1], a
    ld [W_WindowManager_VWFRingEnd + 1], a
    ld [W_WindowManager_VWFRingWriteHead + 1], a
    ld hl, W_WindowManager_CompositionArea
    ld b, 16
.clearComposition
    ld a, [W_WindowManager_CompositionBackground]
    ld [hli], a
    ld a, [W_WindowManager_CompositionBackground + 1]
    ld [hli], a
    dec b
    jr nz, .clearComposition

    ld a, e
    ldh [REG_VBK], a
    ld hl, $8A00 ;36 tiles, ring $020-$043.
    ld bc, $0240
.clearStage
.waitVRAM
    ldh a, [REG_STAT]
    and 3
    cp 3
    jr z, .waitVRAM
    ld a, $FF ;VWF description background color.
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearStage

    ; A separate blank tile fills positions not touched by short strings.
    ld hl, $97F0
    ld b, 16
.clearStageBlank
    call .waitInitVRAM
    ld a, $FF
    ld [hli], a
    dec b
    jr nz, .clearStageBlank

    xor a
    ldh [REG_VBK], a
    ld hl, $9941
    call .initTileRow
    ld hl, $9981
    call .initTileRow
    ld a, 1
    ldh [REG_VBK], a
    ld a, e
    and a
    ld e, 3
    jr z, .stageAttrReady
    ld e, $0B
.stageAttrReady
    ld hl, $9941
    call .initAttrRow
    ld hl, $9981
    call .initAttrRow

    pop af
    ldh [REG_VBK], a
    pop af
    ldh [REG_SVBK], a
    pop hl
    pop de
    pop bc
    pop af
    ret

.initTileRow
    ld b, 18
.nextInitTile
    call .waitInitVRAM
    ld a, $7F
    ld [hli], a
    dec b
    jr nz, .nextInitTile
    ret

.initAttrRow
    ld b, 18
.nextInitAttr
    call .waitInitVRAM
    ld a, e
    ld [hli], a
    dec b
    jr nz, .nextInitAttr
    ret

.waitInitVRAM
    ldh a, [REG_STAT]
    and 3
    cp 3
    jr z, .waitInitVRAM
    ret

MobileMenu_DescCommit::
    push af
    push bc
    push de
    push hl
    ldh a, [REG_SVBK]
    push af
    ldh a, [REG_VBK]
    push af
    di
    ; Four 18-byte rows fit in one VBlank. Wait for its first scanline so the
    ; old description remains visible until both tilemap banks are copied.
.waitVBlank
    ldh a, [REG_LY]
    cp 144
    jr nz, .waitVBlank

    xor a
    ldh [REG_VBK], a
    ld hl, $9941
    ld de, $9D41
    call .copyRow
    ld hl, $9981
    ld de, $9D81
    call .copyRow
    ld a, 1
    ldh [REG_VBK], a
    ld hl, $9941
    ld de, $9D41
    call .copyRow
    ld hl, $9981
    ld de, $9D81
    call .copyRow

    ei
    pop af
    ldh [REG_VBK], a
    pop af
    ldh [REG_SVBK], a
    pop hl
    pop de
    pop bc
    pop af
    ret

.copyRow
    ld b, 18
.nextCopy
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .nextCopy
    ret
