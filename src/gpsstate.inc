	

	#define GPS_FLAGS_GPSOK 0   ; True if the GPS has given us a fix and is happy
	#define GPS_FLAGS_WEST 1    ; True if West, false if East
	#define GPS_FLAGS_SOUTH 2   ; True if South, false if North
	#define GPS_FLAGS_LONGITUTE_HUNDREDS 3	; True if the longitude is above 100. (NOT MIC-E RULES)

	EXTERN gps_flags
	EXTERN gps_longitude_deg
	EXTERN gps_longitude_min
	EXTERN gps_longitude_centi
	EXTERN gps_lattitude_deg
	EXTERN gps_lattitude_min
	EXTERN gps_lattitude_centi
	EXTERN gps_heading
	EXTERN gps_speed_knots
	EXTERN gps_fix_hours
	EXTERN gps_fix_mins
	EXTERN gps_fix_secs