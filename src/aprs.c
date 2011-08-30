/*
 * aprs.c
 */


#include "aprs.h"
#include "modem.h"

#define APRS_CONTROL_UNPROTO_NOPOLL 0x03  /* Control field value - UI frame with no polling request (P=0) */
#define APRS_PROTOCOL_NO_LAYER_3    0xF0  /* PID for no layer 3 protocol */

#pragma code
/**
 * Fill a callsign structure with the given sign and SSID
 */
void aprsMakeCallsignPgm(t_ax25Callsign *buffer,
		                 const rom char *callsign,
		                 unsigned char ssid)
{
	char i;
	overlay char *dst = buffer->callsign;
	for(i = 6; i && (*dst++ = (*callsign++ << 1)); i--);
	dst--; // Rewind that 0. Good job flags is there to save from overrun
	for(   ; i ; i--) *dst++ = (' '<<1);

	buffer->flags.value = (ssid & 0x0F) << 1;
}

void aprsSendPacket(auto t_aprsPacket *packet)
{
    overlay char *ptr;

    // Use the "repeated" flags on the source and desination address to signify a command
    packet->to.flags.isRepeated = 1;
    packet->from.flags.isRepeated = 0;

    // Send the initial flags
    modemStartPacket();

    // Send the address.
    // If no "last" flag has been set this will go horribly wrong, so we set one
    packet->path[APRS_MAX_REPEATERS-1].flags.isLast = 1;
    for(ptr = (char *)packet;
        (*ptr & 1) == 0;
        modemPutc(*ptr++));

    // Control and PID
    modemPutc(APRS_CONTROL_UNPROTO_NOPOLL);
    modemPutc(APRS_PROTOCOL_NO_LAYER_3);

    // Message
    for(ptr = packet->message;
        *ptr;
        modemPutc(*ptr++));

    // Send the CRC and the final flags
    modemEndPacket();
}
