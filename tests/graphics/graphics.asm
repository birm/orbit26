;-----------
; BIRM
; Test 4 - graphics
;-----------
  processor 6502
  include "vcs.h"
  include "macro.h"

  seg.u Variables
  org  $80

X_POS byte;
Y_POS byte;
METRONOME byte;
MET_TIMER byte;
SCORE byte;
MELODY_PTR word;
MEL_COLOR_PTR word;
SPEED_FACTOR byte;
SHIP_POINTER byte;
LEVEL byte;
NEXT_LEVEL byte;

  seg Code
  org $F000

Reset:
  CLEAN_START

;----------------
; init vars
;----------------
  lda #$01
  sta LEVEL
  lda #$00
  sta SCORE
  lda #$08
  sta NEXT_LEVEL
  lda #$80 ; middle of screen
  sta X_POS
  sta Y_POS
  lda #$FF
  sta METRONOME
  lda #$00
  sta MET_TIMER
  lda #$40
  sta SPEED_FACTOR
  lda #<Melody
  sta MELODY_PTR
  lda #>Melody
  sta MELODY_PTR+1
  lda #<MelodyColors
  sta MEL_COLOR_PTR
  lda #>MelodyColors
  sta MEL_COLOR_PTR+1

  ;--------------
  ; init settings
  ;--------------
  lda #%00000001
  sta CTRLPF

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
; sound routines
;----------------
  jsr PercussionSound
  jsr MelodySound

Metronome:
  lda MET_TIMER
  adc SPEED_FACTOR
  sta MET_TIMER
  bcc SkipMetronome
  sec
  sta MET_TIMER
  ldx METRONOME
  dex
  stx METRONOME

SkipMetronome:
  nop

  lda #%00000010
  REPEAT 37
    sta WSYNC
  REPEND
  lda $0
  sta VBLANK

;-------------
;input checks
;-------------

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
  lda #$F0
  bit INPT4
  bne IsNone
  lda METRONOME
  and #%00000011 ; only update score once per cycle
  bne IsNone ; check if close enough after too
  lda METRONOME
  and #%00000111 ; is this a hit?
  bne IsMiss
  ldx SCORE
  inx
  stx SCORE
  jmp IsNone

IsMiss:
  ldx SCORE
  cpx #0
  beq IsNone
  dex
  stx SCORE

IsNone:
  nop

;-------------------
; display functions
;-------------------
  lda #100		 ; Above the ship
  ;sbc SCORE
  tax
LoopVisible1:
  lda METRONOME ; 0-255
  REPEAT 3
     lsr ; divide by 2^3
  REPEND
  tay
  lda (MEL_COLOR_PTR),Y ; get the color associated with this beat
  sta COLUBK
  lda #1
  sta WSYNC
	dex
	bne LoopVisible1  ; loop while X != 0

  ldx #7 ; 8 lines of ship visibility
PlayerVisible:
  lda METRONOME ; 0-255
  REPEAT 3
     lsr ; divide by 2^4
  REPEND
  tay
  lda (MEL_COLOR_PTR),Y ; get the color associated with this beat
  sta COLUBK
  lda SCORE
  lsr
  tay
  lda ScoreColors,Y ; get planet score color (lower)
  sta COLUP0
  lda Ship,X
  REPEAT 20
    nop
  REPEND
  sta GRP0
  lda #1
  sta WSYNC
  dex
  bpl PlayerVisible  ; loop while X >= 0

  lda #0
  sta GRP0

  lda #76		 ; between the ship and ground
  adc SCORE
  tax
LoopVisible2:
  lda METRONOME ; 0-255
  REPEAT 3
     lsr ; divide by 2^3
  REPEND
  tay
  lda (MEL_COLOR_PTR),Y ; get the color associated with this beat
  sta COLUBK
  lda #1
  sta WSYNC
	dex
	bpl LoopVisible2  ; loop while X >= 0

  ldx #7 ; 8 lines of planet visibility
PlanetVisible:
  lda METRONOME ; 0-255
  REPEAT 3
     lsr ; divide by 2^4
  REPEND
  tay
  lda (MEL_COLOR_PTR),Y ; get the color associated with this beat
  sta COLUBK
  lda SCORE
  lsr
  tay
  lda ScoreColors,Y ; get planet score color (upper)
  sta COLUPF
  lda Planet,X
  sta PF1
  lda #$FF
  sta PF2
  lda #1
  sta WSYNC
  dex
  bpl PlanetVisible  ; loop while X >= 0

  lda #0
  sta PF2
  sta PF1

;-----------------
; Leveling up
;-----------------
LevelChange:
  ldy LEVEL
  lda SCORE
  cmp NEXT_LEVEL
  bcc NoLevelChange
  ldx LEVEL
  inx; increase level by 1
  stx LEVEL
  lda NEXT_LEVEL
  adc #$04
  sta NEXT_LEVEL
  lda SPEED_FACTOR
  asl; increase speed by 2x
  sta SPEED_FACTOR
  cmp #0
  beq ResetTime ; if you win, reset. I'm not making a kill screen

NoLevelChange:
  nop

  jmp Screen ; next frame

ResetTime:
  jmp Reset

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
  REPEAT 1
     lsr ; divide by 2^4
  REPEND
  sta AUDV0
  rts

MelodySound subroutine
  lda METRONOME ; 0-255
  REPEAT 3
     lsr ; divide by 2^3 to get 0-32
  REPEND
  tax
  lda Melody,X ; get the note associated with this beat
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

  .byte #$05
  .byte #$05
  .byte #$06
  .byte #$07
  .byte #$08
  .byte #$08
  .byte #$05
  .byte #$06

  .byte #$06
  .byte #$03
  .byte #$06
  .byte #$03
  .byte #$08
  .byte #$04
  .byte #$03
  .byte #$03

  .byte #$05
  .byte #$05
  .byte #$06
  .byte #$07
  .byte #$08
  .byte #$08
  .byte #$05
  .byte #$06

MelodyColors:
  .byte #$86
  .byte #$86
  .byte #$88
  .byte #$8A
  .byte #$8C
  .byte #$8C
  .byte #$84
  .byte #$88

  .byte #$81
  .byte #$81
  .byte #$83
  .byte #$85
  .byte #$87
  .byte #$87
  .byte #$80
  .byte #$83

  .byte #$56
  .byte #$53
  .byte #$56
  .byte #$53
  .byte #$58
  .byte #$54
  .byte #$53
  .byte #$53

  .byte #$81
  .byte #$81
  .byte #$83
  .byte #$85
  .byte #$87
  .byte #$87
  .byte #$80
  .byte #$83
;---------------
; store graphics
;---------------
Planet:
  .byte #%01111111
  .byte #%00111111
  .byte #%00011111
  .byte #%00001111
  .byte #%00000111
  .byte #%00000011
  .byte #%00000001
  .byte #%00000000

ScoreColors:
  .byte #$40 ; Dark red
  .byte #$46 ; Medium red
  .byte #$4E ; Light red
  .byte #$1A ; Yellow
  .byte #$DE ; Light green
  .byte #$C6 ; medium green
  .byte #$C4 ; medium green again
  .byte #$C0 ; Dark Green

Ship:
  .byte #%11000000 ; "good" frame
  .byte #%00100000
  .byte #%10110000
  .byte #%01111100
  .byte #%01111100
  .byte #%10110000
  .byte #%00100000
  .byte #%11000000

;---------------
; PAD, reset
;---------------
  org $FFFC
  word Reset
  word Reset
