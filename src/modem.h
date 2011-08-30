/***************************************************************
 * C include file for the modem.asm routines
 ***************************************************************/

#ifndef _MODEM_H_
#define _MODEM_H_

/**
 * Initialise the modem output and state.
 */
extern void modemSetup(void);

/**
 * Key the radio and enter TX mode.
 */
extern void modemTxMode(void);

/**
 * Unkey the radio and enter RX mode.
 */
extern void modemRxMode(void);

/**
 * Start the modem, sending flags and setting state for a frame.
 * Synchronous.
 */
extern void modemStartPacket(void);

/**
 * Send a byte
 */
extern void modemPutc(unsigned char c);

/**
 * Stop the modem
 */
extern void modemEndPacket(void);


/**
 * Generate a tone for testing
 */
extern void modemStartTone(unsigned char high);

/**
 * Stop the tone generator
 */
extern void modemToneStop(void);

#endif
