;------------------------------------------------------------------------------
; This file was auto-generated by PICStateGenerator. Do not edit.
; Generated: Mon Oct 31 21:07:09 GMT 2011
;------------------------------------------------------------------------------
#ifndef _GPS_H_
#define _GPS_H_

;------------------------------------------------------------------------------
; Initialisation method.
; Call before first use.
;------------------------------------------------------------------------------
              EXTERN   gpsInit

;------------------------------------------------------------------------------
; Step method.
; Call to advance state machine after setting input.
;------------------------------------------------------------------------------
              EXTERN   gpsStep
              EXTERN   gpsLatitudeDegMin
              EXTERN   gpsFlags
              EXTERN   gpsLongitudeHundredths
              EXTERN   gpsTime
              EXTERN   gpsLongitudeDegMin
              EXTERN   gpsQuality
              EXTERN   gpsLatitudeHundredths
              EXTERN   gpsInput


;------------------------------------------------------------------------------
; Access Variables
;------------------------------------------------------------------------------
              EXTERN   gpsFlags
#define FLAG_GPS_NEW_POSITION (0)
#define FLAG_GPS_NORTH (1)
#define FLAG_GPS_EAST (2)
              EXTERN   gpsInput


;------------------------------------------------------------------------------
; Variables for bank gpsBank1
;------------------------------------------------------------------------------
              EXTERN   gpsLatitudeDegMin
              EXTERN   gpsLongitudeHundredths
              EXTERN   gpsTime
              EXTERN   gpsLongitudeDegMin
              EXTERN   gpsQuality
              EXTERN   gpsLatitudeHundredths

#endif
