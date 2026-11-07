; reset_patch.s - replaces the enhanced IIe EF ROM's RESET/PWRUP block,
; $FA62-$FAD4, with: init, banner, "SLOT?", one key, boot $Cn00 (0 = Applesoft cold
; start; a card that returns lands in an Applesoft warm start).
        .setcpu "65C02"

SETNORM = $FE84
INIT    = $FB2F
SETVID  = $FE93
SETKBD  = $FE89
GOTOCX  = $FBB4         ; Y = internal-ROM function; 9 = IIe reset housekeeping
HOME    = $FC58
COUT    = $FDED
KBD     = $C000
KBDSTRB = $C010
LCROM   = $C082         ; language card: read ROM, write-protect RAM
CLRAN0  = $C058
CLRAN1  = $C05A
CXDESEL = $CFFF         ; any access releases slot $C800 expansion ROMs
MSLOT   = $07F8         ; $Cn of the slot whose firmware is running
BOOTPTR = $00           ; $00/$01 = $Cn00, as the autostart scan uses
BELL    = $FF3A         ; LDA #$87 / JMP COUT
BASIC   = $E000         ; Applesoft cold start (JMP $F128)
WARM    = $E003         ; Applesoft warm start (JMP $D43C), program kept
BANNER  = $FB60         ; stock: JSR HOME, copy $FF0A-$FF12 to $040F-$0417

        .org $FA62
RESET:                  ; $FA62, the 6502 reset vector target
        bit LCROM       ; LC RAM out first: ROM readable, RAM write-protected
        cld
        jsr SETNORM     ; INVFLG = $FF
        jsr INIT        ; text mode, full window
        jsr SETVID      ; CSW -> COUT1
        jsr SETKBD      ; KSW -> KEYIN
        lda CLRAN0
        lda CLRAN1
        ldy #$09
        jsr GOTOCX      ; 80-col off, AN2/AN3 off, Solid-Apple self test,
                        ; Open-Apple memory scramble, slot-3 ROM select
        lda CXDESEL
        bit KBDSTRB     ; discard any key pressed before now
        jsr BANNER      ; HOME + "Apple //e"; exits DEY/BNE, so Y = 0
msgloop: lda msg,y
        bpl getkey      ; stops on badkey's JSR opcode ($20, bit 7 clear)
        jsr COUT        ; COUT1 saves/restores Y via YSAV1 ($35)
        iny
        bra msgloop

msg:    .byte 'S'|$80, 'L'|$80, 'O'|$80, 'T'|$80, '?'|$80
                        ; no terminator: badkey must follow directly

badkey: jsr BELL        ; anything but 0-7: beep, drop it, wait again
        bra getkey
launch: lda #' '|$80    ; A reaches $Cn00; slot 3 prints it, so make it a space
        jsr bootjmp     ; no indirect JSR: this pushes the return address
        jmp WARM        ; a card whose $Cn00 code ends in RTS (80-col slot 3) lands here
bootjmp: jmp (BOOTPTR)
        .assert * <= $FAA6, error, "RESET part overruns PWRUP entry"
        .res $FAA6 - *, $EA
PWRUP:  bra RESET       ; $FAA6: "CALL -1370" and friends land here

getkey: lda KBD
        bpl getkey
        sta KBDSTRB
        cmp #'0'|$80
        bcc badkey
        cmp #'8'|$80
        bcs badkey
        pha
        jsr COUT        ; echo the digit, left up for the length of the beep
        jsr BELL
        jsr HOME
        pla             ; not relying on COUT/BELL/HOME to keep A
        and #$0F        ; '0'..'7' -> 0..7
        beq cold
        ora #$C0
        sta BOOTPTR+1
        sta MSLOT
        stz BOOTPTR
        bra launch
cold:   jmp BASIC

        .assert * <= $FAD5, error, "patch overruns $FAD4"
        .res $FAD5 - *, $EA
