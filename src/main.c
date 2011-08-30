/****************************************************************
 * PICC 18 implementation for M0RJC Tracker                     *
 * Developing in Assembler is too slow.                         *
 ****************************************************************/

#include <p18f14k50.h>
#include <string.h>
#include <delays.h>
#include <stdlib.h>
#include "buildconfig.inc.h"
#include "modem.h"
#include "aprs.h"

#pragma config WDTEN=OFF  	// disable watchdog timer
#pragma config MCLRE = OFF  // MCLEAR Pin on
#pragma config DEBUG = ON	// Enable Debug Mode
#pragma config LVP = OFF	// Low-Voltage programming disabled (necessary for debugging)
#pragma config CPB = OFF	// Code Protect
#pragma config CP0 = OFF	// Code Protect
#pragma config CP1 = OFF	// Code Protect
//	#pragma config FOSC = IRCCLKOUT;Internal oscillator, clock out on pin 3
// #pragma config FOSC = IRC	// Internal oscillator, pin 3 is IO
#pragma config FOSC = OSCILLATOR_CHOICE
#pragma config HFOFST = OFF	// Start on HFINTOSC immediately
#pragma config PLLEN = OFF	// Do not scale the clock up
#pragma config XINST = OFF	// Do not use extended instructions


#pragma udata  // Get it out of SHARE
static t_aprsPacket s_packet;


#pragma code
void main(void)
{
    int count = 0;
    char buffer[20];

    OSCCON = OSCCON_VALUE;	// Sets 16MHz

	modemSetup();
	
	aprsMakeCallsignPgm(&(s_packet.to), APRS_ADDRESS_TEST, APRS_DESTINATION_SSID_NONE);
    aprsMakeCallsignPgm(&(s_packet.from), "M0RJC", 9);
	aprsSetLastAddress(&(s_packet.from));

	while(1)
	{
		modemTxMode();

		modemStartTone(0);
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		modemStartTone(1);
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz

		strcpypgm2ram(s_packet.message, ">Test Message from M0RJC tracker project");
		aprsSendPacket(&s_packet);

		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz


        strcpypgm2ram(s_packet.message, ":M0RJC    :If you can read this it works. ");
        itoa(count++, buffer);
        strcat(s_packet.message, buffer);
		aprsSendPacket(&s_packet);

		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz


        strcpypgm2ram(s_packet.message, ":M0RJC    :Message Again. ");
        itoa(count++, buffer);
        strcat(s_packet.message, buffer);
        aprsSendPacket(&s_packet);


		modemRxMode();

		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
		Delay10KTCYx(0); // 2,560,000 cycles * 4MHz
	}	
}
