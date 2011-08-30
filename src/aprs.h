/*
 * C routines to send APRS packets.
 *
 * Uses the lower level modem.c and modem.h
 *
 * See http://www.aprs.org/doc/APRS101.PDF for the APRS specification.
 */

#ifndef _APRS_H_
#define _APRS_H_

#ifndef MEM_MODEL
#define MEM_MODEL far
#endif

#define APRS_MAX_MESSAGE_LENGTH 61  /* APRS spec allows 256 - too much for here */
#define APRS_MAX_REPEATERS 3        /* APRS spec allows 8 - may need this if we start digipeating  */

/** Generic destination address to use for TEST. It has an SSID of 0 unless using repeater SSIDs */
#define APRS_ADDRESS_TEST	        "TEST"
/** Generic destination address to use for Experimental Software. The 000 is a version string. SSID is 0 */
#define APRS_ADDRESS_EXPERIMENTAL  "APZ000"

/**
 * The SSID in the Destination Address field of all packets is coded to specify
 * the APRS digipeater path. If the Destination Address SSID is 0, the packet
 * follows the standard AX.25 digipeater (“VIA”) path contained in the Digipeater
 * Addresses field of the AX.25 frame.
 * If the Destination Address SSID is non-zero, the packet follows one of 15
 * generic APRS digipeater paths
 */
#define APRS_DESTINATION_SSID_NONE              0
#define APRS_DESTINATION_SSID_WIDE1_1           1
#define APRS_DESTINATION_SSID_WIDE2_2           2
#define APRS_DESTINATION_SSID_WIDE3_3           3
#define APRS_DESTINATION_SSID_WIDE4_4           4
#define APRS_DESTINATION_SSID_WIDE5_5           5
#define APRS_DESTINATION_SSID_WIDE6_6           6
#define APRS_DESTINATION_SSID_WIDE7_7           7
#define APRS_DESTINATION_SSID_NORTH_PATH        8
#define APRS_DESTINATION_SSID_SOUTH_PATH        9
#define APRS_DESTINATION_SSID_EAST_PATH        10
#define APRS_DESTINATION_SSID_WEST_PATH        11
#define APRS_DESTINATION_SSID_NORTH_PATH_WIDE  12
#define APRS_DESTINATION_SSID_SOUTH_PATH_WIDE  13
#define APRS_DESTINATION_SSID_EAST_PATH_WIDE   14
#define APRS_DESTINATION_SSID_WEST_PATH_WIDE   15

/**
 * Every APRS packet contains an APRS Data Type Identifier (DTI). This
 * determines the format of the remainder of the data in the Information field.
 */
#define APRS_MESSAGE_TYPE_MESSAGE ':'
#define APRS_MESSAGE_TYPE_STATUS  '>'

/**
 * An address character is an ASCII character shifted left. The bottom bit would signify the end
 * of the address field - though that is not going to happen in an address character.
 */
typedef union
{
    struct
    {
        unsigned isLast :1;
        unsigned ch :7;
    };
    unsigned char value;
} t_ax25AddressChar;

/**
 * An AX25 address found in the header of the packet.
 */
typedef struct
{
    //	t_ax25AddressChar callsign[6];
    unsigned char callsign[6];
    union
    {
        struct
        {
            unsigned isLast:1;     // LSB - Is the last address
            unsigned ssid:4;       // SSID
            unsigned :2;           // Reserved
            unsigned isRepeated:1; // MSB - 1=repeated. In the source and destination signifies Command/Response
        };
        unsigned char value;
    } flags;
} t_ax25Callsign;

/**
 * An APRS packet.
 */
typedef struct
{
    t_ax25Callsign to;
    t_ax25Callsign from;
    t_ax25Callsign path[APRS_MAX_REPEATERS]; // The protocol allows more
    // PID and Control are hard coded for APRS
   	const char message[APRS_MAX_MESSAGE_LENGTH + 1]; // null terminated message string
} t_aprsPacket;

/**
 * Fill a callsign structure with the given sign and SSID
 */
extern void aprsMakeCallsignPgm(t_ax25Callsign *buffer,
        const rom char *callsign, unsigned char ssid);

/**
 * Set this address to be the last
 */
#define aprsSetLastAddress(ptrAddress) ( (ptrAddress)->flags.isLast = 1 )

/**
 * Send the given packet
 */
extern void aprsSendPacket(auto t_aprsPacket *packet);

#endif
