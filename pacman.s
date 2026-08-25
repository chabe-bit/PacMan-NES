; INES Header
; Signatures the program that it's a valid NES software 

H_MIRROR = 0
V_MIRROR = 1   

.segment "HEADER"
INES_MAPPER = 0
INES_MIRROR = H_MIRROR
INES_SRAM   = 0

.include "lib.s"

; INES format 
; https://www.nesdev.org/wiki/INES
.byte 'N', 'E', 'S', $1A
.byte $02 ; 16kb PRG 
.byte $01 ; 8kb  CHR
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $F) << 4)
.byte (INES_MIRROR & $11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; flags 7-15 UNUSED 


; VECTORS 
.segment "VECTORS"
.word nmi 
.word reset 
.word irq 

; ZEROPAGE
; In the zero page, keep memory here limited. Memory used here must be reserved in advanced as it is the RAM, compare to that of the ROM.
; RAM -> Temporal data that releases when the console is powered off OR Save data. Relevant uses would be for keeping track of the player's current score and high score. 
; ROM -> Static/Persistent data where you want to keep your code and assets (PRG and CHR)
.segment "ZEROPAGE"
nmi_ready:  .res 1
ppu_ct10:   .res 1 
ppu_ct11:   .res 1 

.segment "CODE"
.proc WaitFrame 
    inc nmi_ready
@loop:
    lda nmi_ready
    bne @loop
    rts 
.endproc

.segment "CODE"
.proc UpdatePPU
    lda ppu_ct10
    ; 0x00 | 0x80 
    ; 0000 0000 | 1111 0000
    ; A -> 1111 1111
    ora #VBLANK_NMI
    sta ppu_ct10
    sta PPU_CONTROL 
    
    ; Code Architecture 
    ; We load the value from ppu_ct10 into the A register, we expect this the last updated value 
    ; OR operate on A via VBLANK register  
    ; Store and update ppu_ct10 so it's last updated value is used (pointer for me)
    ; Store into $2000, the hardware register. The VBLANK's been turned on so firing it into this register now responds with the hardware, in this case, to blank the screen. 
    
    lda ppu_ct11 
    ora #OBJ_ON | BG_ON 
    sta ppu_ct11 
    jsr WaitFrame 
    rts 
.endproc


.segment "CODE"
.proc DisablePPU
    
.endproc 
