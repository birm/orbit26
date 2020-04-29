;-----------
; BIRM
; Test 1 - sounds
;-----------
  processor 6502
  include "vcs.h"
  include "macro.h"

  seg.u Variables
  org  $80

X_POS byte;
Y_POS byte;
METRONOME byte;

  seg Code
  org $F000

Reset:
  CLEAN_START

;----------------
; init vars
;----------------
  lda #$80 ; middle of screen
  sta X_POS
  sta Y_POS
  lda #$FF
  sta METRONOME

Screen:
;----------------
; vsync
;----------------
  lda #%00000010
  sta VBLANK
  sta VSYNC
  REPEAT 3
    sta WSYNC
  REPEND
  lda #0
  sta VSYNC
;----------------
; per-frame, before draw
;----------------
  jsr MakeSound
  REPEAT 37
    sta WSYNC
  REPEND
  lda $0
  sta VBLANK
  stx METRONOME
  dex
  stx METRONOME

IsRight:
  lda #$80
  bit SWCHA
  bne IsLeft
  inc X_POS

IsLeft:
  lda #$40
  bit SWCHA
  bne IsDown
  dec X_POS

IsDown:
  lda #$20
  bit SWCHA
  bne IsUp
  dec Y_POS

IsUp:
  lda #$10
  bit SWCHA
  bne IsFire
  inc Y_POS

IsFire:
    lda #$80
    bit INPT4
    bne IsNone
    stx METRONOME
    dex
    stx METRONOME

IsNone:
  lda $0

  jmp Screen

MakeSound subroutine
  lda X_POS ; 0-255
  REPEAT 3
     lsr ; divide by 2^3
  REPEND
  sta AUDF0 ; note via x position
  lda Y_POS ; 0-255
  REPEAT 4
     lsr ; divide by 2^4
  REPEND
  sta AUDC0 ; note via x position
  lda METRONOME
  REPEAT 7
     lsr ; divide by 2^8
  REPEND
  sta AUDV0
  rts
;---------------
; PAD, reset
;---------------
  org $FFFC
  word Reset
  word Reset
