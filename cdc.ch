This change-file is for demo/main.w

TODO: rm both "default:" and all unused cases (see via wireshark) + add "Reset MCU"


IMPORTANT: Never send more than one bank size less one byte to the host at a time, so that we
don't block while a Zero Length Packet (ZLP) to terminate the transfer is sent if the host isn't
listening.
-----------
In general, USB uses a less-than-max-length packet to demarcate an end-of-transfer. So in the case
of a transfer which is an integer multiple of max-packet-length, a ZLP is used for demarcation.
You see this in bulk pipes a lot. For example, if you have a 4096 byte transfer, that will be
broken down into an integer number of max-length packets plus one zero-length-packet. If the SW
driver has a big enough receive buffer set up, higher-level SW receives the entire transfer at
once, when the ZLP occurs.
-----------
Just never send anything if DTR is not active.
Then you may use the trick between ---- ---- and don't afraid the thing mentioned before ----
Because driver will flush everything which was not transmitted to application when tty
is closed (fix the driver to do so if it does not do this).

@** Data throughput, latency and handshaking issues.
The Universal Serial Bus may be new to some users and developers. Here are
described the major architecture differences that need to be considered by both software and
hardware designers when changing from a traditional RS232 based solution to one that uses
the USB to serial interface devices.

@* The need for handshaking.
USB data transfer is prone to delays that do not normally appear in systems that have been used
to transferring data using interrupts. The original COM ports of a PC were directly connected
to the
motherboard and were interrupt driven. When a character was transmitted or received (depending
if FIFO's are used) the CPU would be interrupted and go to a routine to handle the data. This
meant that a user could be reasonably certain that, given a particular baud rate and data rate,
the
transfer of data could be achieved without any real need for flow control. The hardware interrupt
ensured that the request would get serviced. Therefore data could be transferred without using
handshaking and still arrive into the PC without data loss.

@* Data transfer comparison.
USB does not transfer data using interrupts. It uses a scheduled system and as a result, there can
be periods when the USB request does not get scheduled and, if handshaking is not used, data
loss will occur. An example of scheduling delays can be seen if an open application is dragged
around using the mouse.

For a USB device, data transfer is done in packets. If data is to be sent from the PC, then a
packet
of data is built up by the device driver and sent to the USB scheduler. This scheduler puts the
request onto the list of tasks for the USB host controller to perform. This will typically take
at least
1 millisecond to execute because it will not pick up the new request until the next 'USB Frame'
(the
frame period is 1 millisecond). Therefore there is a sizable overhead (depending on your required
throughput) associated with moving the data from the application to the USB device. If data were
sent 'a byte at a time' by an application, this would severely limit the overall throughput of the
system as a whole.

@* Continuous data --- smoothing the lumps.
Data is received from USB to the PC by a polling method. The driver will request a certain amount
of data from the USB scheduler. This is done in multiples of 64 bytes. The 'bulk packet size' on
USB is a maximum of 64 bytes. The host controller will read data from the device until either:

a) a packet shorter than 64 bytes is received or
b) the requested data length is reached

The device driver will request packet sizes between 64 Bytes and 4 Kbytes. The size of the packet
will affect the performance and is dependent on the data rate. For very high speed, the largest
packet size is needed. For 'real-time' applications that are transferring audio data at 115200 Baud
for example, the smallest packet possible is desirable, otherwise the device will be holding up
4k of
data at a time. This can give the effect of 'jerky' data transfer if the USB request size is too
large
and the data rate too low (relatively).

@* Small amounts of data or end of buffer conditions.
When transferring data from a USB-Serial or USB-FIFO IC device to the PC, the device will
send the data given one of the following conditions:

1. The buffer is full (64 bytes made up of 2 status bytes and 62 user bytes).

2. One of the RS232 status lines has changed (USB-Serial chips only). A change of level (high
or low) on CTS\# / DSR\# / DCD\# or RI\# will cause it to pass back the current buffer even
though it may be empty or have less than 64 bytes in it.

3. An event character had been enabled and was detected in the incoming data stream.

4. A timer integral to the chip has timed out. There is a timer (latency timer) in some
chips that measures the time since data was last
sent to the PC. The default value of the timer is set to 16 milliseconds.
The value of the timer is adjustable from 1 to 255 milliseconds.
Every time data is
sent back to the PC the timer is reset. If it times-out then the chip will send back the 2 status
bytes and any data that is held in the buffer.

From this it can be seen that small amounts of data (or the end of large amounts of data), will be
subject to a 16 millisecond delay when transferring into the PC. This delay should be taken along
with the delays associated with the USB request size as mentioned in the previous section. The
timer value was chosen so that we could make advantage of 64 byte packets to fill large buffers
when in high speed mode, as well as letting single characters through. Since the value chosen for
the latency timer is 16 milliseconds, this means that it will take 16 milliseconds to receive an
individual character, over and above the transfer time on serial or parallel link.

For large amounts of data, at high data rates, the timer will not be used. It may be used to send
the last packet of a block, if the final packet size works out to be less than 64 bytes. The
first 2
bytes of every packet are used as status bytes for the driver. This status is sent every 16
milliseconds, even when no data is present in the device.

A worst case condition could occur when 62 bytes of data are received in 16 milliseconds. This
would not cause a timeout, but would send the 64 bytes (2 status + 62 user data bytes) back to
USB every 16 milliseconds. When the USB driver receives the 64 bytes it would hold on
to them and request another 'IN' transaction. This would be completed another 16 milliseconds
later and so on until USB driver gets all of the 4K of data required. The overall time would
be (4096 / 64) * 16 milliseconds = 1.024 seconds between data packets being received by the
application. In
order to stop the data arriving in 4K packets, it should be requested in smaller amounts. A short
packet (< 64 bytes) will of course cause the data to pass from USB driver back to the chip
driver for
use by the application.

For application programmers it must be stressed that data should be sent or received using buffers
and not individual characters.

@** Effect of USB buffer size and the latency timer on data throughput.
An effect that is not immediately obvious is the way the size of the USB total packet request
has on
the smoothness of data flow. When a read request is sent to USB, the USB host controller will
continue to read 64 byte packets until one of the following conditions is met:

1. It has read the requested size (default is 4 Kbytes).

2. It has received a packet shorter than 64 bytes from the chip.

3. It has been cancelled.

While the host controller is waiting for one of the above conditions to occur, NO data is
received by
our driver and hence the user's application. The data, if there is any, is only finally
transferred after
one of the above conditions has occurred.

Normally condition 3 will not occur so we will look at cases 1 and 2. If 64 byte packets are
continually sent back to the host, then it will continue to read the data to match the block size
requested before it sends the block back to the driver. If a small amount of data is sent, or the
data is sent slowly, then the latency timer will take over and send a short packet back to the host
which will terminate the read request. The data that has been read so far is then passed on to the
users application via the chip driver. This shows a relationship between the latency timer,
the data
rate and when the data will become available to the user. A condition can occur where if data is
passed into the chip at such a rate as to avoid the latency timer timing out, it can take a long
time between receiving data blocks. This occurs because the host controller will see 64 byte
packets at the point just before the end of the latency period and will therefore continue to
read the
data until it reaches the block size before it is passed back to the user's application.

The rate that causes this will be:

62 / Latency Timer bytes/Second

(2 bytes per 64 byte packet are used for status)

For the default values: -

62 / 0.016 ~= 3875 bytes /second ~= 38.75 KBaud

Therefore if data is received at a rate of 3875 bytes per second (38.75 KBaud) or faster, then the
data will be subject to delays based on the requested USB block length. If data is received at a
slower rate, then there will be less than 62 bytes (64 including our 2 status bytes) available
after 16
milliseconds. Therefore a short packet will occur, thus terminating the USB request and passing
the data back. At the limit condition of 38.75 KBaud it will take approximately 1.06 seconds
between data buffers into the users application (assuming a 4Kbyte USB block request buffer size).

To get around this you can either increase the latency timer or reduce the USB block request.
Reducing the USB block request is the preferred method though a balance between the 2 may be
sought for optimum system response.

USB Transfer (buffer) size can be adjusted in the chip. Transmit buffer and receive buffer
are separate. TODO: read Dimitrov's arduino forum thread about this.
@^TODO@>

The size of the USB block requested can be adjusted in the chip.

@* Event Characters.
If the event character is enabled and it is detected in the data stream, then the contents of the
devices buffer is sent immediately. The event character is not stripped out of the data stream by
the device or by the drivers, it is up to the application to remove it. Event characters may
be turned
on and off depending on whether large amounts of random data or small command sequences are
to be sent. The event character will not work if it is the first character in the buffer. It
needs to be
the second or higher. The reason for this being applications that use the Internet for example,
will
program the event character as `\$7E'. All the data is then sent and received in packets that have
`\$7E' at the start and at the end of the packet. In order to maximise throughput and to avoid a
packet with only the starting `\$7E' in it, the event character does not trigger on the first
position.

@* Flushing the receive buffer using the modem status lines.
Flow control can be used by some chips to flush
the buffer in the chip. Changing one of the modem status lines will do this. The modem status
lines can be controlled by an external device or from the host PC itself. If an unused output line
(DTR) is connected to one of the unused inputs (DSR), then if the DTR line is changed by the
application program from low to high or high to low, this will cause a change on DSR and make it
flush the buffer.

@* Flow Control.
Some chips use their own handshaking as an
integral part of its design, by proper use of the TXE\# line. Such chips can use RTS/CTS,
DTR/DSR hardware or XOn/XOff software handshaking.
It is highly recommended that some form of handshaking be used.

There are 4 methods of flow control that can be programmed for some devices.

1. None - this may result in data loss at high speeds

2. RTS/CTS - 2 wire handshake. The device will transmit if CTS is active and will drop RTS if it
cannot receive any more.

3. DTR/DSR - 2 wire handshake. The device will transmit if DSR is active and will drop DTR if it
cannot receive any more.

4. XON/XOFF - flow control is done by sending or receiving special characters. One is XOn
(transmit on) the other is XOff (transmit off). They are individually programmable to any value.

It is strongly encouraged that flow control is used because it is impossible to ensure that the
chip
driver will always be scheduled. The chip can buffer up to 384 bytes of data. Kernel can 'starve'
the driver program of time if it is doing other things. The most obvious example of this is moving
an application around the screen with the mouse by grabbing its task bar. This will result in a lot
of
graphics activity and data loss will occur if receiving data at 115200 baud (as an example) with no
handshaking. If the data rate is low or data loss is acceptable then flow control may be omitted.


@ TODO: first make it work as it is now, and then make it as similar to |dev_desc| in
kbd.w as possible (except 5th byte, maybe VID PID bytes)
@^TODO@>

@c
code const S_device_descriptor dev_desc =
{
  sizeof(usb_dev_desc),
  0x01, @/
  0x0200, @/
  0x02, /* CDC */
  0x00, @/
  0x00, @/
  EP0_SIZE,
  0x03EB, /* VID */
  0x2018, /* PID */
  0x1000, @/
  0x00, @/
  0x00, @/
  0x00, @/
  1
};

@ To receive data on an OUT endpoint:

@c
#if 0
    UEINTX &= ~(1 << RXOUTI);
    <read UEDATX>
    UEINTX &= ~(1 << FIFOCON);
#endif

------------------
  case 0x0300: @/
    @<Handle {\caps get descriptor string} (language)@>@;
    break;
  case 0x03 << 8 | MANUFACTURER: @/
    @<Handle {\caps get descriptor string} (manufacturer)@>@;
    break;
  case 0x03 << 8 | PRODUCT: @/
    @<Handle {\caps get descriptor string} (product)@>@;
    break;
  case 0x03 << 8 | SERIAL_NUMBER: @/
    @<Handle {\caps get descriptor string} (serial)@>@;
    break;
------------------
@ @<Handle {\caps get descriptor string} (serial)@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(NULL, 1 + 1 + SN_LENGTH * 2); /* multiply because Unicode */
------------------
Here we also handle one case when data (serial number) needs to be transmitted from memory,
not from program.

@<Functions@>=
void send_descriptor(const void *buf, int size)
{
  @<Fill in serial number if |buf == NULL|@>@;
#if 1
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE)
        break;
      UEDATX = from_program ? pgm_read_byte(buf++) : *(uint8_t *) buf++;
--------------------------
@ @d MANUFACTURER 0x01
@d PRODUCT 0x02
@d SERIAL_NUMBER 0x03
@d NOT_USED 0x00

@<Global \null variables@>=
const S_device_descriptor dev_desc
----------------------------
@*1 Language descriptor.

This is necessary to transmit manufacturer, product and serial number.
------------------------------
@*1 Serial number descriptor.

This one is different in that its content cannot be prepared in compile time,
only in execution time. So, it cannot be stored in program memory.
Therefore, a special trick is used in |send_descriptor| (to avoid cluttering it with
arguments): we pass a null pointer if serial number is to be transmitted.
In |send_descriptor| |sn_desc| is filled in.

@d SN_LENGTH 20 /* length of device signature, multiplied by two (because each byte in hex) */

@<Global \null variables@>=
struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  int16_t wString[SN_LENGTH];
} sn_desc;

@ @<Fill in serial number if |buf == NULL|@>=
int from_program = 1;
if (buf == NULL) {
  from_program = 0;
  @<Get serial number@>@;
  buf = &sn_desc;
}

@ @d SN_START_ADDRESS 0x0E
@d hex(c) c<10 ? c+'0' : c-10+'A'

@<Get serial number@>=
sn_desc.bLength = 1 + 1 + SN_LENGTH * 2; /* multiply because Unicode */
sn_desc.bDescriptorType = 0x03;
uint8_t addr = SN_START_ADDRESS;
for (uint8_t i = 0; i < SN_LENGTH; i++) {
  uint8_t c = boot_signature_byte_get(addr);
  if (i & 1) { /* we divide each byte of signature into halves, each of
                  which is represented by a hex number */
    c >>= 4;
    addr++;
  }
  else c &= 0x0F;
  sn_desc.wString[i] = hex(c);
}
---------------------------------

@ initialization of out endpoint structure
@d OUT (0 << 7)
@c
/*  \.{OUT \char'174\ 2} */

 @i control-endpoint-management.w

 @i IN-endpoint-management.w

@* OUT endpoint management.

There is only one stage (data). It corresponds to the following transaction(s):
\bigskip
$$\hbox to6cm{\vbox to0.94cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=1700}}\hfil}$$
$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to16cm{\vbox to4.29cm{\vfil\special{psfile=OUT.eps
  clip llx=0 lly=0 urx=1348 ury=362 rwi=4535}}\hfil}$$

Make it work with tel.w + invert leds.

@x
  DDRF &= ~(1 << PF4), PORTF |= 1 << PF4; /* input */
  DDRF &= ~(1 << PF5), PORTF |= 1 << PF5; /* input */
  DDRF &= ~(1 << PF6), PORTF |= 1 << PF6; /* input */
  DDRD |= 1 << PD7; /* ground */
@y
  PORTD |= 1 << PD5; /* led off */
  DDRE |= 1 << PE6;
  PORTE |= 1 << PE6; /* |DTR| pin high */
@z

@x
    if (usb_configuration_nb != 0) { /* do not allow to receive data before
                                        end of enumeration FIXME: does this make any sense? */
      if (UCSR1A & 1 << UDRE1) {
        UENUM = EP2;
        if (UEINTX & 1 << RXOUTI) {
          rx_counter = UEBCLX;
          if (rx_counter == 0) PORTD |= 1 << PD5; /* this cannot happen */
          while (rx_counter) {
            while (!(UCSR1A & 1 << UDRE1)) ;
            UDR1 = UEDATX;
            rx_counter--;
            if (rx_counter == 0)
              UEINTX &= ~(1 << RXOUTI), UEINTX &= ~(1 << FIFOCON);
          }
        }
      }
      if (cpt_sof >= 100) { /* debounce (FIXME: how is this even supposed to work?) */
        unsigned char data;
        if (!(PINF & 1 << PF4)) {
          data = '*'; @+ uart_usb_send_buffer(&data, 1);
          serial_state.bDCD = 1;
        }
        else
          serial_state.bDCD = 0;
        if (!(PINF & 1 << PF5)) {
          data = '0'; @+ uart_usb_send_buffer(&data, 1);
        }
        if (!(PINF & 1 << PF6)) {
          data = '#'; @+ uart_usb_send_buffer(&data, 1);
          serial_state.bDSR = 1;
        }
        else
          serial_state.bDSR = 0;
        @<Notify host if |serial_state| changed@>@;
      }
      if (usb_request_break_generation == 1) {
        usb_request_break_generation = 0;
        PORTB ^= 1 << PB0;
        @<Reset MCU@>@;
      }
    }
@y
@z

@x
line_status.all = UEDATX | UEDATX << 8;
@y
line_status.all = UEDATX | UEDATX << 8;
if (line_status.DTR) {
  PORTE &= ~(1 << PE6); /* |DTR| pin low */
  PORTB |= 1 << PB0; /* led off */
}
else {
  PORTE |= 1 << PE6; /* |DTR| pin high */
  PORTB &= ~(1 << PB0); /* led on */
}
@z
