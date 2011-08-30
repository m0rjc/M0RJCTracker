PIC18 Based APRS Tracker Project
================================

This is an APRS tracker project targetted at PIC18.
It is initially very incomplete!

It started out as a port of another tracker (OpenTracker I think) to Assembler
because I didn't have a C compiler. The code depended on Hi-Tech-C and its
optimisations. I've since caved in and started using 
PIC C18. Hopefuly I can make this work using only the optimisation available in
the "Lite" version of this compiler - so this code will remain accessible to
people without expensive tools.

The PIC18 is only slightly more expensive than the PIC16 series commonly
used for trackers. It has the following advantages:

 * Built in clock that can run up to 32MHz. I had been running at 16MHz.
   It's not a crystal, but looks reasonably accurate in the lab. The test
   will be in the field and wildly varying temperatures. The datasheet
   gives +-5% over the working temperature range, 2% if I keep it above
   freezing point and below 60degC. I have found that unfortunately this
   is not accurate enough for the receiver software I am using to test,
   though there is the option of trying to use the GPS module's 1 second
   pulse to compensate the internal clock.

 * The VCref voltage reference output makes quite a good digital to
   analogue converter, enabling me to output the signal without the
   external resistor network.

 * There is good support for C. Even at assembler level there are some nicer op-codes.

The Hardware
------------

I'm developing using a PIC 18F14K50. 

My GPS module comes from RF Solutions.
   http://www.rfsolutions.co.uk/acatalog/Board_Level_GPS_Receiver_Module.html the DS-622R
When I bought it, it was quite cheap. It doesn't seem to like saving configuration changes to its
flash RAM, so is stuck at 9600 baud. Not a problem here. Output is LVTTL.

I have an old LCD display hanging around. I'm rapidly running out of pins to drive it.

The radio is a Yaesu VX-7R. That should not matter.

Both PIC and GPS can run low voltage, which offers interesting options for low power. The LCD looks
very power hungry.

Pin assignment so far: (Items in brackets can be worked around or changed)

 RA0	(PGD)
 RA1	(PGC)
 RA3	(�MCLR)
 RA4	AN3		Audio in from radio. Central bias. To detect Busy, and one day to decode?
 RA5
 
 RB4 (I2C)
 RB5	RX		GPS module, or computer for programming
 RB6 (I2C)	
 RB7	TX		Computer for programming. Could use as something else when not talking to computer?
                        Assumes I can get away without having to send commands to the GPS.
 
 RC0			
 RC1		
 RC2	Cvref		Audio out to radio.
 RC3	
 RC4
 RC5
 RC6
 RC7

I will need to assign PTT IN, PTT OUT and whatever controls I may use. Maybe the two PTTs could be combined,
though that could increase external circuitry. 

The Plan
--------

 * I now have AX25 wave generation complete. 
      See http://www.flickr.com/photos/m0rjc/6041105197/in/photostream/lightbox/

 * I have Generated and "transmited" a hard coded test message. I could receive it using APRS software
      with the output from the PIC connected to the PC's mic input.

 * Receive information from the GPS module in interrupts using a state machine.
     I am working on a state engine generator to make this easier to create and maintain.
     The same generator can then be used for command interface, or maybe decoding?

 * Provide a means to detect "Radio Busy".
     By detecting audio from the radio.
     Research how I can detect PTT on a connected microphone.
     If possible use the same pin to detect "Busy" on the data port of a radio like the Yaesu 8900.

 * Complete the basic Tracker functions to create a first functioning prototype. Use the simplest
     encoding possible.

Call this Milestone 1

 * I've had to use a crystal to give the stability. It would be interesting to use the internal clock
     and tune it using the 1 pulse per second output from the GPS module. I'd have to leave the option
     to use a crystal for situations where it is used without a module with a 1 pulse per second output.

 * Either complete the Mic-E encoder in assembly, or start again in C. I have now removed the
   part written code, and having blatted the repository I'd have to go to my own backups to
   restore it if I want to return to it. I'm not sure how useful compression is for
   a device like this - apart from perhaps reducing the amount of time during the transmission 
   for clock skew to set in.

 * I've had an LCD display in my bits box for ages, so this is becoming more singing and dancing then
   maybe it could be. Write code to output information to it, but keep it all modular so someone else
   could use this code in a much more lightweight way. The way things are going I may have to look at
   it as an expansion using the I2C bus.

The intended use of this was for situations where I am working with both St John and RAYNET as a cycle
responder. I hope to be able to use the device with a mic, so I can still talk into the radio rather than
having the radio tied up. It would be nice to be able to use the Mic-E status codes and message to indicate
status.


Very Long Term:
---------------

 * I plan to use an ADC input to detect incoming signal from the radio.
     Find a way of decoding incoming data. A couple of options present themselves:

        *  The DTMF Decoder algorithms. I've not seen them settle in the past. Maybe I got them wrong.

        *  Could I make a trellis decoder based on samples? I'd need to lock phase
           (use a comparater to detect zero crossing perhaps?) and somehow ensure I
           know the signal amplitude to work out the trellises. (easy peak detector) 
           It would take some investigation to see if it's possble given resources.
           Theoretically given a sample I should be able to work out where
           the next sample will be for either of the two tone frequencies and compare.
           The trick would be trying to reduce the amount of possibilities because I think
           the maths to handle arbitrary position would be a lot. Sadly if I use an LCD I've
           taken the comparater inputs so have to work entirely with the ADC.


 * If I can decode then that opens up some interesting possibilities
      * Receive messages?
      * Digipeat?
      * Show other stations on a connected Garmin Etrex?
   The limit would be time, and the amount of program and data space in the microcontroller.

 * Experiment with smart track algorithms. I have some interesting ideas. I don't know how
   easy they would be.
