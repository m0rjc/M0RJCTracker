;---------------------------------------------------------------
; EEPROM Configuration
;---------------------------------------------------------------

	GLOBAL configAPRSSymbolTableNormal
	GLOBAL configAPRSSymbolNormal
	GLOBAL configMicEMessageNormal
	GLOBAL configStatusTextNormal

	GLOBAL configAPRSSymbolTableAlternate
	GLOBAL configAPRSSymbolAlternate
	GLOBAL configMicEMessageAlternate
	GLOBAL configStatusTextAlternate

	GLOBAL configAPRSSymbolTableEmergency
	GLOBAL configAPRSSymbolEmergency
	GLOBAL configMicEMessageEmergency
	GLOBAL configStatusTextEmergency

	GLOBAL configVersionText
	
	GLOBAL configMyCallsign
	GLOBAL configDestSSID

CodeConfigEEPROM		CODE

configAPRSSymbolTableNormal		de '/'
configAPRSSymbolNormal			de 'b'   ; Bicycle, (SSID 4)
configMicEMessageNormal			de 7	 ; Off Duty
configStatusTextNormal			de 'F','r','e','e',0,0,0,0,0,0

configAPRSSymbolTableAlternate	de '/'
configAPRSSymbolAlternate		de '+'   ; Red cross
configMicEMessageAlternate		de 5     ; In Service
configStatusTextAlternate		de 'B','u','s','y',0,0,0,0,0,0

configAPRSSymbolTableEmergency	de '\\'
configAPRSSymbolEmergency		de '!'   ; Emergency
configMicEMessageEmergency		de 0	 ; Emergency
configStatusTextEmergency		de 'E','M','E','R','G','E','N','C','Y',0

configVersionText				de 'R','J','C','v','0','.','1',0,0,0

; My callsign shifted to go on the air. The system will add appropriate control bits
; According the to APRS Spec the SSID should be zero. I allow it to be overriden for experimentation.
configMyCallsign		de 'M'<<1,'0'<<1,'R'<<1,'J'<<1,'C'<<1,' ', (0<<1)

; SSID to use in the destination, shifted ready to go on air. The system will add appropriate control bits
; The destination SSID in APRS encodes the repeater path
configDestSSID			de (3<<1) 	; WIDE3-3

	END


