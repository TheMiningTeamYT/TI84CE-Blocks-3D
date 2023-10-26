section .text
assume adl = 1
; 29-48 cycles
; probably has room for improvement
section .text
public abs
abs:
    inc sp    ; 1
    inc sp    ; 1
    inc sp    ; 1
    or a, a    ; 1
    sbc hl, hl ; 2
    add hl, sp ; 1
    inc hl    ; 1
    inc hl    ; 1
    ld a, (hl) ; 2
    pop hl    ; 4
    dec sp    ; 1
    dec sp    ; 1
    dec sp    ; 1
    dec sp    ; 1
    dec sp    ; 1
    dec sp    ; 1
    or a, a   ; 1
    ret p     ; 2 if false, 7 if true -- 24 / 29
    push de ; 4
    ex de, hl  ; 1
    sbc hl, hl ; 2
    sbc hl, de ; 2
    pop de ; 4
    ret       ; 6 -- 43
section .text
public _drawTextureLineA
; Fixed24 startingX, Fixed24 endingX, Fixed24 startingY, Fixed24 endingY, const uint8_t* texture, uint8_t colorOffset
; definitely has room for optimization
_drawTextureLineA:
    di
    ; x1, y1, xStep, yStep, ratio, and column are Fixed24's (the numbers are effectively multiplied by 4096) FYI
    ; save registers
    push ix
    push iy
    ; MUHAHA iy IS the stack pointer now!
    ld iy, 9
    add iy, sp
    ld ix, x1 
    ; grab arguments off the stack
    ; save stack pointer
    ld (startingSP),sp
    ld bc, (iy)
    ld (ix), bc
    ld hl, (iy + 3)
    or a, a
    ; dx is now in hl
    sbc hl, bc
    ; dx is now in de
    ex de, hl
    ld bc, (iy + 6)
    ld (ix + 3), bc
    ld hl, (iy + 9)
    or a, a
    ; dy is now in hl
    sbc hl, bc
    ; push dx & dy to the stack
    push hl ; dy
    push de ; dx
    ; grab absolute value of dx & dy
    ; hl: dy, de: dx
    push hl
    call abs
    ; hl: dx, de: abs(dy)
    ex de, hl
    ld (iy - 18), hl
    call abs
    ld (iy - 18), hl; save abs(dx) to the stack
    ; hl: abs(dx), de: abs(dy)
    or a, a
    sbc hl, de
    pop hl
    jp m, y_is_greater
    ex de, hl

    y_is_greater:
    ex de, hl

    cont_length:
    ; length is in hl
    ld bc, 4096
    add hl, bc
    push hl
    push bc
    ld l, (iy - 16) ; upper bits in l
    ld a, h ; middle bits in a
    srl l
    rra
    srl l
    rra
    srl l
    rra
    srl l
    rra
    ex de, hl
    or a, a
    sbc hl, hl
    ld h, e
    ld l, a
    ld (ix + 21), hl
    call _fp_div
    ; the reciprocal of the length is now in hl
    inc sp
    inc sp
    inc sp
    ld (iy - 18), hl
    ; the reciprocal of the length is now in bc
    exx
    ld bc, (iy - 18)
    exx
    call _fp_mul
    ld (ix + 6), hl
    inc sp
    inc sp
    inc sp
    exx
    ld (iy - 15), bc
    exx
    call _fp_mul
    ld (ix + 9), hl
    exx
    or a, a
    sbc hl, hl
    ; store 0 into column
    ld (ix + 12), hl
    add hl, bc
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld (ix + 15), hl
    exx
    ld hl, (iy + 12)
    ld (ix + 18), hl
    ld a, (iy + 15)
    ld b, 160
    ld c, a
    exx
    ld hl, (ix + 21)
    ld bc, 1
    exx
    ld iy, x1 
    ; 321 cycles -- probably room for optimization
    fillLoop:
        ; ix: screen pointer
        ; iy: variable pointer (later texture pointer)

        ; 5 cycles
        ld ix, gfx_vram ; 5

        ; 11 cyles
        ; move on X
        ld de, (iy) ; 5
        ld hl, (iy + 6) ; 5
        add hl,de ; 1

        ; 17 cycles
        ; make sure that x isn't 320 or greater, else cap it to 319
        ex de, hl ; 1
        ld hl, 1310719 ; 4
        or a, a ; 1
        sbc hl, de ; 2
        jp p, x_1 ; 5
        ld de, 1306624 ; 4

        x_1:
        ; 32 cycles
        ld (iy), de ; 6
        ld e, (iy + 2) ; 4 // upper bits in e
        ld a, d ; 1 // middle bits in a
        ; bit shifting
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        or a, a ; 1
        sbc hl, hl ; 2
        ; effectively shift it right 8 by putting the upper 8 bits (e) into the middle 8 bits of hl (h)
        ; and the middle 8 bits (a) into the lower 8 bits of hl (l)
        ld h,e ; 1
        ld l,a ; 1
        ex de, hl ; 1

        ; 2 cycles
        ; Set ix
        add ix,de ; 2

        ; 11 cycles
        ; move on Y
        ld de, (iy + 3) ; 5
        ld hl, (iy + 9) ; 5
        add hl,de ; 1

        ; 21 cycles
        ; check that y is less than 239, else cap it to 238
        ex de, hl ; 1
        ld hl, 978944 ; 4
        or a, a ; 1
        sbc hl, de ; 2
        jp p, y_1 ; 5
        ld de, 974848 ; 4

        ; 28 cycles
        y_1:
        ld (iy + 3), de ; 6
        ld e, (iy + 5) ; 4 // upper bits in e
        ld a, d ; 1 // middle bits in a
        ; bit shifting
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        srl e ; 2
        rra ; 1
        or a, a ; 1
        sbc hl, hl ; 2
        ; effectively shift it right 8 by putting the upper 8 bits (e) into the middle 8 bits of hl (h)
        ; and the middle 8 bits (a) into the lower 8 bits of hl (l)
        ld h,e ; 1
        ld l,a ; 1


        ; 11 cycles
        ; Set IY
        ; Multiply HL by 320
        ; since hl (the y value) should be less than 256 (or 240),
        ; we can discard the middle and upper 8 bits and use mlt
        ; muliply l by 160
        ld h, b ; 1
        mlt hl ; 6
        ; add hl to itself (multiply by 2)
        add hl,hl ; 1
        ex de, hl ; 1
        ; add this value to the screen pointer
        add ix, de ; 2

        ; Get column
        ; 26 cycles
        ld d, (iy + 13) ; 4
        srl d ; 2
        srl d ; 2
        srl d ; 2
        srl d ; 2
        ld hl, (iy + 18) ; 5
        ld iy, 0 ; 4
        ld iyl, d ; 2
        ex de, hl ; 1
        add iy, de ; 2

        ; At this point we should have a pointer to the texture in IX and a pointer to the screen location in IY
        ; Copy pixel
        ; 19 cycles
        ld a, (iy + 0) ; 4
        add a, c ; 1
        ld (ix + 0),a ; 4
        ld de,320 ; 4
        add ix, de ; 2
        ld (ix + 0),a ; 4

        ; advance column
        ld iy, x1 ; 5
        ld de,(iy + 12) ; 5
        ld hl,(iy + 15) ; 5
        add hl,de ; 1
        ld (iy + 12),hl ; 6

        ; 10 cycles
        endOfLoop:
        exx ; 1
        or a,a ; 1
        sbc hl, bc ; 2
        exx ; 1
        jp p, fillLoop ; 5
    ; the end:
    ld sp,(startingSP)
    pop iy
    pop ix
    ei
    ret
    ; trick the compiler
    ld (x1), hl
    ld (y1), hl
    ld (xStep), hl
    ld (yStep), hl
    ld (column), hl
    ld (ratio), hl
    ld (length), hl
    ld (texture), hl
    ld (startingSP), hl
    ld (colorOffset), hl
    ld (returnAddress), hl
section .text
public _int_sqrt_a
; unsigned int n
; returns in hl
_int_sqrt_a:
    di
    push iy
    ld iy, 0
    add iy, sp

    ; number we are getting sqrt of is in de
    ld de, (iy + 6)
    or a, a
    sbc hl, hl
    inc hl
    sbc hl, de
    ; if number is 0 or 1, the square root is no different
    jp p, zero_or_one

    ; get number of bits
    or a, a
    ld a, 24
    ld hl, $7FFFFF
    sbc hl, de
    ; if the number already has 1 in the first position, move on
    jp m, count_cont ; 5
    count_loop:
        add hl, de ; 1
        dec a ; 1
        ex de, hl ; 1
        add hl, hl ; 1
        ex de, hl ; 1
        sbc hl, de ; 2
        jp p, count_loop ; 5
    count_cont:
    ld b, a
    and a, 1
    add a, b
    exx
    or a, a
    sbc hl, hl
    ex de, hl
    sbc hl, hl
    exx
    ; result is in de'
    ; result squared is in hl'
    ; n will be in hl
    ; worst case scenario for 1 loop is 305 cycles -- not bad, not great
    sqrt_loop:
        sub a, 2 ; 2
        exx ; 1
        ex de, hl ; 1
        add hl, hl ; 1
        ex de, hl ; 1
        add hl, hl ; 1
        add hl, hl ; 1
        add hl, de ; 1
        inc de ; 1
        add hl, de ; 1
        push hl ; 4
        exx ; 1
        ld hl, (iy + 6) ; 6
        or a, a ; 1
        jr z, shift_cont ; 3
        ld b, (iy + 8) ; 4
        ld c, a ; 1
        ; 11 cycles -- nice
        shift_loop:
            sra b ; 2
            rr h ; 2
            rr l ; 2
            sub a, 1 ; 2
            jr nz, shift_loop ; 3
        ld a, c ; 1
        push hl ; 4
        ld (iy - 4), b ; 4
        pop hl ; 4
        ; at this point, shifted n is in hl
        shift_cont:
        pop de ; 4
        ; result squared is now in de
        or a, a ; 1
        sbc hl, de ; 2
        jp p, sqrt_loop_end ; 5
            exx ; 1
            or a, a ; 1
            sbc hl, de ; 2
            dec de ; 1
            sbc hl, de ; 2
            exx ; 1
        sqrt_loop_end:
        or a, a ; 1
        jr nz, sqrt_loop ; 3
    exx
    push de
    exx
    pop de
    zero_or_one:
    ex de, hl
    the_end:
    ld sp, iy
    pop iy
    ei
    ret
section .text
; Takes a Fixed24 and converts it to an int
; is this faster? IDK!
public _fp_to_int
_fp_to_int:
    push ix ; 4
    ld ix, 0 ; 5
    add ix, sp ; 2
    ld d, (ix + 8) ; 4
    ld a, (ix + 7) ; 4  
    sra d ; 2
    rra ; 1
    sra d ; 2
    rra ; 1
    sra d ; 2
    rra ; 1
    sra d ; 2
    rra ; 1
    ld e, a ; 1 // put middle bits into e
    ld a, d ; 1 // put upper bits into a
    or a, a ; 1
    jp p, number_is_positive ; 4/5 (38/39)
    ld hl, $FFFFFF ; 4
    jr fp_to_int_end
    number_is_positive:
    sbc hl, hl ; 2
    fp_to_int_end:
    ld h, d ; 1
    ld l, e ; 1
    pop ix ; 4
    ret ; 6 (53/57)
section .data
private gfx_vram
gfx_vram = $D40000
private x1
x1: db 3 dup 00h
private y1
y1: db 3 dup 0
private xStep
xStep: db 3 dup 0
private yStep
yStep: db 3 dup 0
private column
column: db 3 dup 0
private ratio
ratio: db 3 dup 0
private texture
texture: db 3 dup 0
private length
length: db 3 dup 0
private startingSP
startingSP: db 3 dup 0
private colorOffset
colorOffset: db 3 dup 0
private returnAddress
returnAddress: db 3 dup 0
extern _fp_div
extern _fp_mul
extern __imulu
extern __ishru