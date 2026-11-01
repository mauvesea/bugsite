INCLUDE "bugsite.inc"

SECTION "WindowManager Tile Text Advice", ROMX[$6200], BANK[$3]

WindowManager_ADVICE_PrintChara::
    ld a, [W_LCDC_SetAttrVal]
    and $F7
    ld [W_LCDC_SetAttrVal], a
    call LCDC_PokeTilemap

    ld a, [W_LCDC_PokeTileX]
    inc a
    ld [W_LCDC_PokeTileX], a
    ret

WindowManager_ADVICE_PrintNewline::
    ret

WindowManager_ADVICE_AutoNewline::
    ld a, [W_WindowManager_ContentsXMin]
    ld [W_LCDC_PokeTileX], a
    ld a, [W_WindowManager_ContentsYMax]
    ld d, a

    ld a, [W_LCDC_PokeTileY]
    inc a
    cp d
    jr c, .noScrollupContents

    push bc
    call WindowManager_ScrollUpContents
    call WindowManager_ScrollUpContents
    pop bc
    ret

.noScrollupContents
    ld a, [W_LCDC_PokeTileY]
    inc a
    inc a
    ld [W_LCDC_PokeTileY], a
    ret

WindowManager_ADVICE_ClearRegion::
    ld a, [W_LCDC_PokeTileX]
    ld b, a
    ld a, [W_LCDC_PokeTileY]
    ld c, a
    ret

WindowManager_ADVICE_OpSCRCURS::
    call BugVM_PopTypedData
    ld a, c
    ld [W_LCDC_PokeTileY], a

    call BugVM_PopTypedData
    ld a, c
    ld [W_LCDC_PokeTileX], a
    ret

WindowManager_ADVICE_OpWINCURS::
    call BugVM_PopTypedData
    ld a, [W_WindowManager_ContentsYMin]
    add a, c
    ld [W_LCDC_PokeTileY], a

    call BugVM_PopTypedData
    ld a, [W_WindowManager_ContentsXMin]
    add a, c
    ld [W_LCDC_PokeTileX], a
    ret

WindowManager_ADVICE_PrintChoices::
    ld a, [W_WindowManager_ChoiceYCoord]
    inc a
    ld [W_WindowManager_ChoiceYCoord], a

    call WindowManager_PrintText

    ld a, BANK(W_WindowManager_ChoiceStringStorage)
    ldh [REG_SVBK], a
    ret

WindowManager_ADVICE_END::
