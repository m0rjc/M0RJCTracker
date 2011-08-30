; ---------------------------------------------------------------------
; AX25 Low Level Modem
;
; Support for synthesis of the AX25 waveform and transmitting AX25
; packets.
; ---------------------------------------------------------------------

;----------------------------------------------------------------------
; TMR0 interrupt handler for modem
;----------------------------------------------------------------------
	EXTERN modem_ISR

;----------------------------------------------------------------------
; Initialise the modem subsystem
;----------------------------------------------------------------------
	EXTERN modem_setup

;----------------------------------------------------------------------
; Enter TX mode. Prepare the sound generator and key the radio.
;                Shut down any input sampling
;----------------------------------------------------------------------
	EXTERN modem_txmode

;----------------------------------------------------------------------
; Enter RX mode. Unkey the radio and shut down the sound generator
;                Start listening to input
;----------------------------------------------------------------------
	EXTERN modem_rxmode

;----------------------------------------------------------------------
; Start transmitting. Output the requisite number of AX25 flags
;                Synchronous call
;----------------------------------------------------------------------
	EXTERN modem_start

;----------------------------------------------------------------------
; Output a byte. Update the CRC
;----------------------------------------------------------------------
	EXTERN modem_putc

;----------------------------------------------------------------------
; Output the CRC and the requisite number of flags.
;----------------------------------------------------------------------
	EXTERN modem_end
