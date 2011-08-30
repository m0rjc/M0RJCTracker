; ---------------------------------------------------------------------
; AX25 Low Level Modem
;
; Support for synthesis of the AX25 waveform and transmitting AX25
; packets.
; ---------------------------------------------------------------------

; Exports for assembly programs
	GLOBAL modem_ISR
	GLOBAL modem_txmode
	GLOBAL modem_rxmode
	GLOBAL modem_setup
	GLOBAL modem_start
	GLOBAL modem_putc
	GLOBAL modem_end

; Exports for C programs
	GLOBAL modemSetup
	GLOBAL modemTxMode
	GLOBAL modemRxMode
	GLOBAL modemStartPacket
	GLOBAL modemPutc
	GLOBAL modemEndPacket

	GLOBAL modemStartTone
	GLOBAL modemStopTone

	list p=18F14K50
	#include p18f14k50.inc
	#include buildconfig.inc.h
	radix dec


#define STEPS_TO_UPDATE_TIMER (.3)  ; How long to do TMR0 -= [VALUE]
#define FULL_WAVE_STEPS (.32)

#define TMR_PERIOD(hz) (CPU_FREQ_MHZ * 250000 / (hz))

#define SAMPLE_PERIOD_1200 (TMR_PERIOD(1200 * 32) - STEPS_TO_UPDATE_TIMER)
#define SAMPLE_PERIOD_2200 (TMR_PERIOD(2200 * 32) - STEPS_TO_UPDATE_TIMER - 1) ; Better high for AGWTracker

#define SAMPLES_PER_BIT_1200 (.32)
#define SAMPLES_PER_BIT_2200 (.59)

; Amount of flags to send at the start and end
#define LEAD_FLAGS .120 ; 100ms
#define TAIL_FLAGS .4

#define AX25_FLAG b'01111110'

; Variables for the interrupt handler  - Access RAM
VarsModemISR 	UDATA_ACS
wave_index          res 1     ; Index into the wave table for current sample
sample_period       res 1     ; Sample period in use, TMR0 ticks
sample_count        res 1     ; Amount of samples output since last bit boundary
fsrtmpl             res 1     ; Temporary store for FSR
fsrtmph             res 1     ; Temporary store for FSR


; Variables for the modem code  - GPR0, non-Access
VarsModem		UDATA

flag                res 1     ; Counter for transmitting AX25 flags
bit                 res 1     ; Bit counter when transmitting a character
ch                  res 1     ; Current character being transmitted
modem_flags         res 1
    #define MODEM_FLAGS_CRC 0           ; Characters contribute to the CRC
    #define MODEM_FLAGS_STUFFING 1      ; Break up long strings of 1s
    #define MODEM_FLAGS_TONE1200 2      ; Current tone being transmitted
crcl                res 1     ; CRC low
crch                res 1     ; CRC high
stuff_count         res 1     ; amount of 1s transmitted since last 0
wave_lookup         res 32    ; Fast lookup for the waveform, sine table 5 bits


; ---------------------------------------------------------------------
; Modem interrupt handler. "Fast" interrupt. 
; ---------------------------------------------------------------------

HighInterruptVector	CODE 0x0008
	GOTO modem_ISR;

LowInterruptVector CODE 0x0018
	RETFIE; Do nothing

CodeModemISR	CODE
modem_ISR:																
	; Backup FSR2 and initialise to base of wave table -1 because W will be 1 indexed
	MOVFF FSR0L, fsrtmpl												
	MOVFF FSR0H, fsrtmph												
	LFSR FSR0, (wave_lookup - 1)										

	; Decrement wave index. If 0 then reset to 32, so result is 1 to 32
	DCFSNZ wave_index, W, A                                            
       MOVLW FULL_WAVE_STEPS										
	MOVWF wave_index, A												

	; Read from wave table and store in DAC
	MOVF PLUSW0, W, A												
	MOVWF REFCON2, A												

	; Restore FSR0	
	MOVFF fsrtmph, FSR0H
	MOVFF fsrtmpl, FSR0L												

	; Decrement timer by sample period. This allows for time taken since the interrupt was fired.
	MOVF sample_period, W, A										
	SUBWF TMR0L, F, A											

	; Add one to the sample count to track time since start of bit
	INCF sample_count, F, A											

	; Re-enable the timer interrupt
	BCF INTCON, TMR0IF											
	RETFIE FAST 												

CodeModem	CODE

; ---------------------------------------------------------------------
; Switch to TX mode
; ---------------------------------------------------------------------
modemTxMode:
modem_txmode:
	RETURN

; ---------------------------------------------------------------------
; Switch to RX mode
; ---------------------------------------------------------------------
modemRxMode:
modem_rxmode:
	RETURN

; ---------------------------------------------------------------------
; Modem Setup
; ---------------------------------------------------------------------
modemSetup:
modem_setup:
; Set up interrupts to give priority
	BSF RCON, IPEN, A
	BSF INTCON, GIEH, A
	BSF INTCON, GIEL, A

;
;  Initialise the DAC
;        REFCON0 = '10010000'   Fixed Voltage Reference Enabled, 1V output
;        REFCON1 = '111x10x0'   DAC enabled, output on pin, source is FVR against GND
;        REFCON2 = '---nnnnn'   5 bit signal out. 10us max settling time gives up to 100kS/s. We're running slower.
	MOVLW b'10010000'
	MOVWF REFCON0, A
	MOVLW b'11101000'
	MOVWF REFCON1, A

;  Load the wave table into RAM
	LFSR FSR0, wave_lookup
	MOVLW UPPER(WaveTable)
	MOVWF TBLPTRU, A
	MOVLW HIGH(WaveTable)
	MOVWF TBLPTRH, A
	MOVLW LOW(WaveTable)
	MOVWF TBLPTRL, A

	MOVLW 32
modem_setupCopyLoop:
	TBLRD*+
	MOVFF TABLAT, POSTINC0
	ADDLW -1
	BNZ modem_setupCopyLoop

;  Set the wave index to 1 (it cannot be zero)
	MOVLW 1
	MOVWF wave_index, A
	MOVFF wave_lookup, REFCON2	; Initial voltage


;
;  Configure the timer         T0CS=0, PSA=1 (no prescaler), 
;                               8 bits, Clock frequency / 4
	MOVLW b'11001000'
	MOVWF T0CON, A
;                               High priority interrupt, initially disabled.
	BSF INTCON2, TMR0IP, A
	BCF INTCON, TMR0IE, A
	BCF INTCON, TMR0IF, A

	RETURN

; ---------------------------------------------------------------------
; Macros
; ---------------------------------------------------------------------

; - Wait for a bit to be sent, if repeated results in a 1 being sent -
waitBit	MACRO
	LOCAL loop
	BANKSEL modem_flags
	MOVLW SAMPLES_PER_BIT_1200
	BTFSS modem_flags, MODEM_FLAGS_TONE1200
		MOVLW SAMPLES_PER_BIT_2200
loop:
	CPFSGT sample_count, A
		GOTO loop
	CLRF sample_count, A
	ENDM	

; - Switch tone between 1200 and 2200 and clear stuffing count -
sendZero MACRO
	BTG modem_flags, MODEM_FLAGS_TONE1200
	MOVLW SAMPLE_PERIOD_1200
	BTFSS modem_flags, MODEM_FLAGS_TONE1200
		MOVLW SAMPLE_PERIOD_2200
	MOVWF sample_period, A
	CLRF stuff_count
	ENDM


; ---------------------------------------------------------------------
; Start generating a 1200Hz tone for tuning.
; This is asynchronous
; ---------------------------------------------------------------------
modemStartTone:
	MOVLW SAMPLE_PERIOD_2200
	MOVWF sample_period, A

	; Read the value off the C stack
	MOVLW 0xFF	; -1
	MOVF PLUSW1, F, A
	BTFSS STATUS, Z, A
		GOTO modemStartToneHigh
	MOVLW SAMPLE_PERIOD_1200	
	MOVWF sample_period, A
modemStartToneHigh:
	SUBLW 0xFF				; Subtract the sample period from overflow point (give or take)
	MOVWF TMR0L, A
	BSF INTCON, TMR0IE, A	; Start tone generator using TMR0
	BCF INTCON, TMR0IF, A
	RETURN


; ---------------------------------------------------------------------
; Start transmitting by firing up the tone generator,
; clearing the CRC and outputting flags
;
; This routine is synchronous, blocking, and runs in the main program
; ---------------------------------------------------------------------
modemStartPacket:
modem_start:
	BANKSEL modem_flags
	CLRF modem_flags		; Results in set 2200, no CRC, no Stuffing
	MOVLW SAMPLE_PERIOD_2200
	MOVWF sample_period, A
	SUBLW 0xFF				; Subtract the sample period from overflow point (give or take)
	MOVWF TMR0L, A
	
	; Reset the CRC
	SETF crch
	SETF crcl

	CLRF sample_count, A
	BSF INTCON, TMR0IE, A	; Start tone generator using TMR0
	BCF INTCON, TMR0IF, A

	MOVLW LEAD_FLAGS
	MOVWF flag				; for(flag = txdelay; flag; flag--)
modem_startFlags:
	MOVLW AX25_FLAG;
	CALL modem_putc
	DECFSZ flag
		GOTO modem_startFlags

	BSF modem_flags, MODEM_FLAGS_CRC
	BSF modem_flags, MODEM_FLAGS_STUFFING
	CLRF stuff_count
	RETURN

; ---------------------------------------------------------------------
; Finish the current packet by sending the CRC, flags and shutting down
; the tone generator
;
; This routine is synchronous, blocking, and runs in the main program
; ---------------------------------------------------------------------
modemEndPacket:
modem_end:
	BANKSEL modem_flags
	BCF modem_flags, MODEM_FLAGS_CRC
	COMF crcl, W  ; W = crcl ^ 0xFF
	CALL modem_putc ; putc(crcl)
	COMF crch, W  ; W = crch ^ 0xFF
	CALL modem_putc ; putc(crch)
	
	BCF modem_flags, MODEM_FLAGS_STUFFING
	MOVLW TAIL_FLAGS
	MOVWF flag
modem_endFlags:
	MOVLW AX25_FLAG;
	CALL modem_putc
	DECFSZ flag
		GOTO modem_endFlags

modemStopTone:
	BCF INTCON, TMR0IE	; Shutdown tone generator which uses TMR0
	RETURN

; ---------------------------------------------------------------------
; Routine to output the value in W as an AX25 character 
; If CRC is enabled then the CRC will be updated.
; If Stuffing is enabled then the character will be stuffed
;
; This routine is synchronous, blocking, and runs in the main program
; ---------------------------------------------------------------------

modemPutc:  ; Read the value off the C stack
	MOVLW 0xFF	; -1
	MOVF PLUSW1, W, A

modem_putc:
	CLRWDT
	BANKSEL ch
	MOVWF   ch
	MOVLW 8
	MOVWF bit

modem_putc_loop:
	; if (crc)
	BTFSS modem_flags, MODEM_FLAGS_CRC
		GOTO modem_putc_nocrc

	; Set CRC[0] to be true if the bit to send != CRC[0]
	MOVLW 1
	BTFSC ch, 0
		XORWF crcl, F

	; Shift right, placing the result from above into Carry
	BCF STATUS, C, A
	RRCF crch, F
	RRCF crcl, F

	; If Carry then XOR in the polynomial
	BNC modem_putc_nocrc
	MOVLW 0x84
	XORWF crch, F
	MOVLW 0x08
	XORWF crcl, F

modem_putc_nocrc:
	; Allow the bit just gone to complete.
	waitBit

	; if the bit to send is 1 then we'd keep sending the same tone.
	; The exception is if we're stuffing, in which case we need to
	; check for 5 1s in a row and if found add an extra zero
	BTFSS ch, 0
		GOTO ax25_sendZero

	INCF stuff_count, F
	BTFSS modem_flags, MODEM_FLAGS_STUFFING	
		GOTO modem_putc_testLoop			; Exit if !stuffing
	MOVLW 5								
	CPFSEQ stuff_count					; Exit if stuff_count != 5
		GOTO modem_putc_testLoop

	waitBit;
ax25_sendZero:
	; Swap the tone and reset the stuffing count
	sendZero

	; // end of for loop
modem_putc_testLoop:
	RRNCF ch, F
	DECFSZ bit
		GOTO modem_putc_loop
	RETURN

; Sine wave lookup table
; 32 step wave for a 5 bit DAC

CodeWaveTable		CODE_PACK

WaveTable:	
      db	0x10
      db	0x13
      db	0x15
      db	0x18
      db	0x1A
      db	0x1C
      db	0x1E
      db	0x1F
      db	0x1F
      db	0x1F
      db	0x1E
      db	0x1C
      db	0x1A
      db	0x18
      db	0x15
      db	0x13
      db	0x10
      db	0x0C
      db	0x0A
      db	0x07
      db	0x05
      db	0x03
      db	0x01
      db	0x00
      db	0x00
      db	0x00
      db	0x01
      db	0x03
      db	0x05
      db	0x07
      db	0x0A
      db	0x0C


	END
