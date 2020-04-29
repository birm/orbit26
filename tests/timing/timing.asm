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
MELODY_PTR word;

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
  lda #<Melody
  sta MELODY_PTR
  lda #>Melody
  sta MELODY_PTR+1

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
  jsr PercussionSound
  jsr MelodySound
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
    inx
    stx METRONOME

IsNone:
  lda $0

  jmp Screen

PercussionSound subroutine
  lda X_POS ; 0-255
  REPEAT 3
     lsr ; divide by 2^3
  REPEND
  sta AUDF0 ; note via x position
  lda Y_POS ; 0-255
  REPEAT 4
     lsr ; divide by 2^4
  REPEND
  sta AUDC0 ; voice via y position
  lda METRONOME
  REPEAT 4
     lsr ; divide by 2^4
  REPEND
  sta AUDV0
  rts

MelodySound subroutine
  lda METRONOME ; 0-255
  REPEAT 5
     lsr ; divide by 2^6
  REPEND
  tay
  lda (MELODY_PTR),Y ; get the note associated with this beat
  sta AUDF1 ; note via timing
  lda #$1
  sta AUDC1 ; preset voice
  lda #8
  sta AUDV1
  rts

;---------------
; Store a "song"
;---------------
Melody:
  .byte #$03
  .byte #$03
  .byte #$04
  .byte #$05
  .byte #$06
  .byte #$06
  .byte #$02
  .byte #$04
;---------------
; PAD, reset
;---------------
  org $FFFC
  word Reset
  word Reset
