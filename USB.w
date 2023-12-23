@* Establishing USB connection.

@ \.{USB\_RESET} signal is sent when device is attached and when USB host reboots.

@d EP0_SIZE 32 /* 32 bytes */

@<Create ISR for connecting to USB host@>=
@.ISR@>@t}\begingroup\def\vb#1{\.{#1}\endgroup@>@=ISR@>
  (@.USB\_GEN\_vect@>@t}\begingroup\def\vb#1{\.{#1}\endgroup@>@=USB_GEN_vect@>)
{
  UDINT &= ~_BV(EORSTI);
  UENUM = 0;
  UECONX &= ~_BV(EPEN);
  UECFG1X &= ~_BV(ALLOC);
  UECONX |= _BV(EPEN);
  UECFG0X = 0;
  UECFG1X = _BV(EPSIZE1); /* 32 bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
  UECFG1X |= _BV(ALLOC);
}

@ @<Setup USB Controller@>=
  UHWCON |= _BV(UVREGE);
  USBCON |= _BV(USBE);
  PLLCSR = _BV(PINDIV);
  PLLCSR |= _BV(PLLE);
  while (!(PLLCSR & _BV(PLOCK))) { }
  USBCON &= ~_BV(FRZCLK);
  USBCON |= _BV(OTGPADE);
  UDIEN |= _BV(EORSTE);

@* Control endpoint management.
(WARNING: these images are incomplete --- they do not show possible handshake
phases)

Device driver sends a
packet to device's EP0. As the data is flowing out from the host, it will end
up in the EP0 buffer. Firmware will then at its leisure read this data. If it
wants to return data, the device cannot simply
write to the bus as the bus is controlled by the host.
Therefore it writes data to EP0 which sits in the buffer
until such time when the host sends a IN packet requesting the
data.\footnote*{This is where the prase ``USB controller has
to manage simultaneous write requests from firmware and host'' from \S22.12.2 of
datasheet becomes clear. (Remember, we use one and the same
endpoint to read {\it and\/} write control data.)}

@*1 Control read (by host). There are the folowing
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\epsfbox{../usb/direction.eps}$$

$$\epsfbox{../usb/control-read-stages.eps}$$

$$\epsfxsize 12.5cm \epsfbox{../usb/control-IN.eps}$$

@ This corresponds to the following transactions:

$$\epsfbox{../usb/transaction-SETUP.eps}$$

$$\epsfbox{../usb/transaction-IN.eps}$$

$$\epsfbox{../usb/transaction-OUT.eps}$$

@*1 Control write (by host). There are the following
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\epsfbox{../usb/direction.eps}$$

$$\epsfbox{../usb/control-write-stages.eps}$$

$$\epsfxsize 16cm \epsfbox{../usb/control-OUT.eps}$$

Commentary to the drawing why ``controller will not necessarily send a NAK at the first IN token''
(see \S22.12.1 in datasheet): If TXINI is already cleared when IN packet arrives, NAKINI is not
set. This corresponds to case 1. If TXINI is not yet cleared when IN packet arrives, NAKINI
is set. This corresponds to case 2.

@ This corresponds to the following transactions:

$$\epsfbox{../usb/transaction-SETUP.eps}$$

$$\epsfbox{../usb/transaction-OUT.eps}$$

$$\epsfbox{../usb/transaction-IN.eps}$$

@* Connection protocol.

@<Global variables@>=
U16 wValue;
U16 wIndex;
U16 wLength;
U16 size;
const void *buf;

@ The following big switch just dispatches SETUP request.
If the name of request begins with {\caps set} - it is host to device.
Data is sent via OUT in data stage.
Confirmation is done via IN with no data.
If the name of request begins with {\caps get} - it is device to host.
Data is sent via IN in data stage.
Confirmation is done via OUT with no data.
If |wLength| is not read, it is zero (no data stage).

@<Process CONTROL packet@>=
switch (UEDATX | UEDATX << 8) { /* Request and Request Type */
case 0x0500: @/
  @<Handle {\caps set address}@>@;
  break;
case 0x0680: @/
  switch (UEDATX | UEDATX << 8) { /* Descriptor Type and Descriptor Index */
  case 0x0100: @/
    @<Handle {\caps get descriptor device}\null@>@;
    break;
  case 0x0200: @/
    @<Handle {\caps get descriptor configuration}@>@;
    break;
  case 0x0300: @/
    @<Handle {\caps get descriptor string} (language)@>@;
    break;
  case 0x0300 | MANUFACTURER: @/
    @<Handle {\caps get descriptor string} (manufacturer)@>@;
    break;
  case 0x0300 | PRODUCT: @/
    @<Handle {\caps get descriptor string} (product)@>@;
    break;
  case 0x0300 | SERIAL_NUMBER: @/
    @<Handle {\caps get descriptor string} (serial)@>@;
    break;
  case 0x0600: @/
    @<Handle {\caps get descriptor device qualifier}@>@;
    break;
  }
  break;
case 0x0900: @/
  @<Handle {\caps set configuration}@>@;
  break;
case 0x2021: @/
  @<Handle {\caps set line coding}@>@;
  break;
case 0x2221: @/
  @<Handle {\caps set control line state}@>@;
  break;
}

@ No OUT packet arrives after SETUP packet, because there is no DATA stage
in this request. IN packet arrives after SETUP packet, and we get ready to
send a ZLP in advance.

@<Handle {\caps set address}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
UEINTX &= ~_BV(TXINI); /* magic packet? */
UDADDR = wValue & 0x7f;
while (!(UEINTX & 1 << TXINI)) { }
UEINTX &= ~_BV(TXINI);
UDADDR |= _BV(ADDEN); /* see \S22.7 in datasheet */

@ When host is booting, BIOS asks 8 bytes in first request of device descriptor (8 bytes is
sufficient for first request of device descriptor). If host is operational,
|wLength| is 64 bytes in first request of device descriptor.
It is OK if we transfer less than the requested amount. But if we try to
transfer more, host does not send OUT packet to initiate STATUS stage.

@<Handle {\caps get descriptor device}\null@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
if (wLength > sizeof dev_desc) size = sizeof dev_desc;
else size = wLength;
buf = &dev_desc;
while (!(UEINTX & _BV(TXINI))) { }
while (size--) UEDATX = pgm_read_byte(buf++);
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { } 
UEINTX &= ~_BV(RXOUTI);                  

@ A high-speed capable device that has different device information for full-speed and high-speed
must have a Device Qualifier Descriptor. For example, if the device is currently operating at
full-speed, the Device Qualifier returns information about how it would operate at high-speed and
vice-versa. So as this device is full-speed, it tells the host not to request
device information for high-speed by using ``protocol stall'' (such stall
does not indicate an error with the device ---~it serves as a means of
extending USB requests).

The host sends an IN token to the control pipe to initiate the DATA stage.

$$\epsfbox{../usb/stall-control-read-with-data-stage.eps}$$

Note, that next token comes after \.{RXSTPI} is cleared, so we set \.{STALLRQ} before
clearing \.{RXSTPI}, to make sure that \.{STALLRQ} is already set when next token arrives.

This STALL condition is automatically cleared on the receipt of the
next SETUP token.

USB\S8.5.3.4, datasheet\S22.11.

@<Handle {\caps get descriptor device qualifier}@>=
UECONX |= 1 << STALLRQ; /* prepare to send STALL handshake in response to IN token of the DATA
  stage */
UEINTX &= ~(1 << RXSTPI);

@ First request is 9 bytes, second is according to length given in response to first request.

@<Handle {\caps get descriptor configuration}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = wLength;
buf = &conf_desc;
while (size) {
  U8 nb_byte = 0;
  while (!(UEINTX & _BV(TXINI))) { }
  while (size && nb_byte++ < EP0_SIZE) UEDATX = pgm_read_byte(buf++), size--;
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(RXOUTI))) { } 
UEINTX &= ~_BV(RXOUTI);                  

@ |wLength| is 255.
@<Handle {\caps get descriptor string} (language)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
size = sizeof lang_desc;
buf = lang_desc;
while (!(UEINTX & _BV(TXINI))) { }
while (size--) UEDATX = pgm_read_byte(buf++);
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ |wLength| is 255.
@<Handle {\caps get descriptor string} (manufacturer)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
size = pgm_read_byte(&mfr_desc.bLength); // TODO: change struct and replace with sizeof
buf = &mfr_desc;
while (!(UEINTX & _BV(TXINI))) { }
while (size--) UEDATX = pgm_read_byte(buf++);
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ |wLength| is 255.
@<Handle {\caps get descriptor string} (product)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
size = pgm_read_byte(&prod_desc.bLength); // TODO: change struct and replace with sizeof
buf = &prod_desc;
while (!(UEINTX & _BV(TXINI))) { }
while (size--) UEDATX = pgm_read_byte(buf++);
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ Here we handle one case when data (serial number) needs to be transmitted from memory,
not from program.
|wLength| is 255.
@<Handle {\caps get descriptor string} (serial)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
size = 1 + 1 + SN_LENGTH * 2;
@<Fill in |sn_desc| with serial number@>@;
buf = &sn_desc;
while (size) {
  U8 nb_byte = 0;
  while (!(UEINTX & _BV(TXINI))) { }
  while (size && nb_byte++ < EP0_SIZE) UEDATX = *(U8 *) buf++, size--;
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ Endpoint 3 (interrupt IN) is not used, but it must be present (for more info
see ``Communication Class notification endpoint notice'' in index).

@d EP1 1
@d EP2 2
@d EP3 3
@d EP1_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP1|.} */
@d EP2_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP2|.} */
@d EP3_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP3|.} */

@<Handle {\caps set configuration}@>=
UEINTX &= ~(1 << RXSTPI);

UENUM = 1;
UECONX &= ~(1 << EPEN);
UECFG1X &= ~(1 << ALLOC);
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1 | 1 << EPDIR; /* bulk\footnote\dag{Must
  correspond to |@<Initialize element 8 ...@>|.}, IN */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP1_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = 2;
UECONX &= ~(1 << EPEN);
UECFG1X &= ~(1 << ALLOC);
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1; /* bulk\footnote\dag{Must
  correspond to |@<Initialize element 9 ...@>|.}, OUT */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP2_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = 3;
UECONX &= ~(1 << EPEN);
UECFG1X &= ~(1 << ALLOC);
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR; /* interrupt\footnote\dag{Must
  correspond to |@<Initialize element 6 ...@>|.}, IN */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP3_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = 0;
while (!(UEINTX & _BV(TXINI))) { }
UEINTX &= ~_BV(TXINI);

@ This is data (7 bytes): 80 25 00 00 00 00 08
Just discard the data.
This is the last request after attachment to host.

@<Handle {\caps set line coding}@>=
UEINTX &= ~_BV(RXSTPI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);
while (!(UEINTX & _BV(TXINI))) { }
UEINTX &= ~_BV(TXINI);

@ {\caps set control line state} requests are sent automatically by the driver when
TTY is opened and closed.

See \S6.2.14 in CDC spec.

@<Handle {\caps set control line state}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
while (!(UEINTX & _BV(TXINI))) { }
UEINTX &= ~_BV(TXINI);
if (wValue == 0) { /* blank the display when TTY is closed */
  for (uint8_t row = 0; row < 8; row++)
    for (uint8_t col = 0; col < NUM_DEVICES*8; col++)
      buffer[row][col] = 0x00;
  @<Display buffer@>@;
}

@* USB stack.

@s U8 int
@s U16 int

@<Type definitions@>=
typedef unsigned char U8;
typedef unsigned short U16;

@*1 Device descriptor.

Placeholder prefixes such as `b', `bcd', and `w' are used to denote placeholder type:

\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it b\hfil} bits or bytes; dependent on context \par
\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it bcd\hfil} binary-coded decimal \par
\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it bm\hfil} bitmap \par
\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it d\hfil} descriptor \par
\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it i\hfil} index \par
\noindent\hskip40pt\hbox to0pt{\hskip-20pt\it w\hfil} word \par

@d MANUFACTURER 1
@d PRODUCT 2
@d SERIAL_NUMBER 3

@<Global variables@>=
struct {
  U8 bLength;
  U8 bDescriptorType;
  U16 bcdUSB; /* version */
  U8 bDeviceClass; /* class code assigned by the USB */
  U8 bDeviceSubClass; /* sub-class code assigned by the USB */
  U8 bDeviceProtocol; /* protocol code assigned by the USB */
  U8 bMaxPacketSize0; /* max packet size for EP0 */
  U16 idVendor;
  U16 idProduct;
  U16 bcdDevice; /* device release number */
  U8 iManufacturer; /* index of manu. string descriptor */
  U8 iProduct; /* index of prod. string descriptor */
  U8 iSerialNumber; /* index of S.N. string descriptor */
  U8 bNumConfigurations;
} const dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  18, /* size of this structure */
  0x01, /* device */
  0x0200, /* USB 2.0 */
  0x02, /* CDC (\S4.1 in CDC spec) */
  0, /* no subclass */
  0, @/
  EP0_SIZE, @/
  0x03EB, /* VID (Atmel) */
  0x2018, /* PID (CDC ACM) */
  0x1000, /* device revision */
  MANUFACTURER, /* (\.{Mfr} in \.{kern.log}) */
  PRODUCT, /* (\.{Product} in \.{kern.log}) */
  SERIAL_NUMBER, /* (\.{SerialNumber} in \.{kern.log}) */
@t\2@> 1 /* one configuration for this device */
};

@*1 Configuration descriptor.

Abstract Control Model consists of two interfaces: Data Class interface
and Communication Class interface.

The Communication Class interface uses two endpoints\footnote*{Although
CDC spec says that notification endpoint is optional, in Linux host
driver refuses to work without it. Besides, notifocation endpoint (EP3) can
be used for DSR signal.},
@^Communication Class notification endpoint notice@>
one to implement a notification element and the other to implement
a management element. The management element uses the default endpoint
for all standard and Communication Class-specific requests.

Theh Data Class interface consists of two endpoints to implement
channels over which to carry data.

\S3.4 in CDC spec.

$$\epsfxsize 7cm \epsfbox{../usb/usb.eps}$$

@<Type definitions@>=
@<Type definition{s} used in configuration descriptor@>@;
typedef struct {
  @<Configuration header descriptor@> @,@,@! el1;
  S_interface_descriptor el2;
  @<Class-specific interface descriptor 1@> @,@,@! el3;
  @<Class-specific interface descriptor 2@> @,@,@! el5;
  @<Class-specific interface descriptor 3@> @,@,@! el6;
  S_endpoint_descriptor el7;
  S_interface_descriptor el8;
  S_endpoint_descriptor el9;
  S_endpoint_descriptor el10;
} S_configuration_descriptor;

@ @<Global variables@>=
const S_configuration_descriptor conf_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize element 1 ...@>, @/
  @<Initialize element 2 ...@>, @/
  @<Initialize element 3 ...@>, @/
  @<Initialize element 4 ...@>, @/
  @<Initialize element 5 ...@>, @/
  @<Initialize element 6 ...@>, @/
  @<Initialize element 7 ...@>, @/
  @<Initialize element 8 ...@>, @/
@t\2@> @<Initialize element 9 ...@> @/
};

@*2 Configuration header descriptor.

@ @<Configuration header descriptor@>=
struct {
   U8 bLength;
   U8 bDescriptorType;
   U16 wTotalLength;
   U8 bNumInterfaces;
   U8 bConfigurationValue; /* number between 1 and |bNumConfigurations|, for
     each configuration\footnote\dag{For some reason
     configurations start numbering with `1', and interfaces and altsettings with `0'.} */
   U8 iConfiguration; /* index of string descriptor */
   U8 bmAttibutes;
   U8 MaxPower;
}

@ @<Initialize element 1 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x02, /* configuration descriptor */
  sizeof (S_configuration_descriptor), @/
  2, /* two interfaces in this configuration */
  1, /* this corresponds to `1' in `cfg1' on picture */
  0, /* no string descriptor */
  0x80, /* device is powered from bus */
@t\2@> 0x32 /* device uses 100mA */
}

@*2 Interface descriptor.

@s S_interface_descriptor int

@<Type definition{s} ...@>=
typedef struct {
   U8 bLength;
   U8 bDescriptorType;
   U8 bInterfaceNumber; /* number between 0 and |bNumInterfaces-1|, for
                                     each interface */
   U8 bAlternativeSetting; /* number starting from 0, for each interface */
   U8 bNumEndpoints; /* number of EP except EP 0 */
   U8 bInterfaceClass; /* class code assigned by the USB */
   U8 bInterfaceSubClass; /* sub-class code assigned by the USB */
   U8 bInterfaceProtocol; /* protocol code assigned by the USB */
   U8 iInterface; /* index of string descriptor */
}  S_interface_descriptor;

@ @<Initialize element 2 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x04, /* interface descriptor */
  0, /* this corresponds to `0' in `if0' on picture */
  0, /* this corresponds to `0' in `alt0' on picture */
  1, /* one endpoint is used */
  0x02, /* CDC (\S4.2 in CDC spec) */
  0x02, /* ACM (\S4.3 in CDC spec) */
  0x01, /* AT command (\S4.4 in CDC spec) */
@t\2@> 0 /* not used */
}

@ @<Initialize element 7 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x04, /* interface descriptor */
  1, /* this corresponds to `1' in `if1' on picture */
  0, /* this corresponds to `0' in `alt0' on picture */
  2, /* two endpoints are used */
  0x0A, /* CDC data (\S4.5 in CDC spec) */
  0x00, /* unused */
  0x00, /* no protocol */
@t\2@> 0 /* not used */
}

@*2 Endpoint descriptor.

@s S_endpoint_descriptor int

@<Type definition{s} ...@>=
typedef struct {
  U8 bLength;
  U8 bDescriptorType;
  U8 bEndpointAddress;
  U8 bmAttributes;
  U16 wMaxPacketSize;
  U8 bInterval; /* interval for polling EP by host to determine if data is available (ms-1) */
} S_endpoint_descriptor;

@ Interrupt IN endpoint serves when device needs to interrupt host.
Host sends IN tokens to device at a rate specified here (this endpoint is not used,
so rate is maximum possible). 

@d IN (1 << 7)

@<Initialize element 6 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  IN | 3, /* this corresponds to `3' in `ep3' on picture */
  0x03, /* transfers via interrupts\footnote\dag{Must correspond to
    |UECFG0X| of |EP3|.} */
  EP3_SIZE, @/
@t\2@> 0xFF /* 256 (FIXME: is it `ms'?) */
}

@ @<Initialize element 8 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  IN | 1, /* this corresponds to `1' in `ep1' on picture */
  0x02, /* bulk transfers\footnote\dag{Must correspond to
    |UECFG0X| of |EP1|.} */
  EP1_SIZE, @/
@t\2@> 0x00 /* not applicable */
}

@ @d OUT (0 << 7)

@<Initialize element 9 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  OUT | 2, /* this corresponds to `2' in `ep2' on picture */
  0x02, /* bulk transfers\footnote\dag{Must correspond to
    |UECFG0X| of |EP2|.} */
  EP2_SIZE, @/
@t\2@> 0x00 /* not applicable */
}

@*2 Functional descriptors.

These descriptors describe the content of the class-specific information
within an Interface descriptor. They all start with a common header
descriptor, which allows host software to easily parse the contents of
class-specific descriptors. Although the
Communication Class currently defines class specific interface descriptor
information, the Data Class does not.

\S5.2.3 in CDC spec.

@*3 Header functional descriptor.

The class-specific descriptor shall start with a header.
It identifies the release of the USB Class Definitions for
Communication Devices Specification with which this
interface and its descriptors comply.

\S5.2.3.1 in CDC spec.

@<Class-specific interface descriptor 1@>=
struct {
  U8 bFunctionLength;
  U8 bDescriptorType;
  U8 bDescriptorSubtype;
  U16 bcdCDC;
}

@ @<Initialize element 3 in configuration descriptor@>= { @t\1@> @/
  5, /* size of this structure */
  0x24, /* interface */
  0x00, /* header */
@t\2@> 0x0110 /* CDC 1.1 */
}

@*3 Abstract control management functional descriptor.

The Abstract Control Management functional descriptor
describes the commands supported by the Communication
Class interface, as defined in \S3.6.2 in CDC spec, with the
SubClass code of Abstract Control Model.

\S5.2.3.3 in CDC spec.

@<Class-specific interface descriptor 2@>=
struct {
  U8 bFunctionLength;
  U8 bDescriptorType;
  U8 bDescriptorSubtype;
  U8 bmCapabilities;
}

@ |bmCapabilities|: Only first four bits are used.
If first bit is set, then this indicates the device
supports the request combination of \.{Set\_Comm\_Feature},
\.{Clear\_Comm\_Feature}, and \.{Get\_Comm\_Feature}.
If second bit is set, then the device supports the request
combination of \.{Set\_Line\_Coding}, \.{Set\_Control\_Line\_State},
\.{Get\_Line\_Coding}, and the notification \.{Serial\_State}.
If the third bit is set, then the device supports the request
\.{Send\_Break}. If fourth bit is set, then the device
supports the notification \.{Network\_Connection}.
A bit value of zero means that the request is not supported.

@<Initialize element 4 in configuration descriptor@>= { @t\1@> @/
  4, /* size of this structure */
  0x24, /* interface */
  0x02, /* ACM */
@t\2@> 1 << 2 | 1 << 1 @/
}

@*3 Union functional descriptor.

The Union functional descriptor describes the relationship between
a group of interfaces that can be considered to form
a functional unit. One of the interfaces in
the group is designated as a master or controlling interface for
the group, and certain class-specific messages can be
sent to this interface to act upon the group as a whole. Similarly,
notifications for the entire group can be sent from this
interface but apply to the entire group of interfaces.

\S5.2.3.8 in CDC spec.

@<Class-specific interface descriptor 3@>=
struct {
  U8 bFunctionLength;
  U8 bDescriptorType;
  U8 bDescriptorSubtype;
  U8 bMasterInterface;
  U8 bSlaveInterface[SLAVE_INTERFACE_NUM];
}

@ @d SLAVE_INTERFACE_NUM 1

@<Initialize element 5 in configuration descriptor@>= { @t\1@> @/
  4 + SLAVE_INTERFACE_NUM, /* size of this structure */
  0x24, /* interface */
  0x06, /* union */
  0, /* number of CDC control interface */
  { @t\1@> @/
@t\2@> 1 /* number of CDC data interface */
@t\2@> } @/
}

@*1 Language descriptor.

This is necessary to transmit manufacturer, product and serial number.

@<Global variables@>=
const U8 lang_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x04, /* size of this structure */
  0x03, /* type (string) */
@t\2@> 0x09,0x04 /* id (English) */
};

@*1 String descriptors.

The trick here is that when defining a variable of type |S_string_descriptor|,
the string content follows the first two elements in program memory.
The C standard says that a flexible array member in a struct does not increase the size of the
struct (aside from possibly adding some padding at the end) but gcc lets you initialize it anyway.
|sizeof| on the variable counts only first two elements.
So, we read the size of the variable at
execution time in |@<Handle {\caps get descriptor string} (manufacturer)@>|
and |@<Handle {\caps get descriptor string} (product)@>| by using |pgm_read_byte|.

TODO: put here explanation from \.{https://stackoverflow.com/questions/51470592/}
@^TODO@>

Is USB each character is 2 bytes. Wide-character string can be used here,
because on GCC for atmega32u4 wide character is 2 bytes.
Note, that for wide-character string I use type `\&{int}', not `\&{wchar\_t}',
because by `\&{wchar\_t}' I always mean 4 bytes (to avoid using `\&{wint\_t}').

@^GCC-specific@>

@s S_string_descriptor int

@<Type definitions@>=
typedef struct {
  U8 bLength;
  U8 bDescriptorType;
  int wString[];
} S_string_descriptor;

#define STR_DESC(@!str) @,@,@,@, {@, 1 + 1 + sizeof str - 2, 0x03, str @t\hskip1pt@>}

@*2 Manufacturer descriptor.

@<Global variables@>=
const S_string_descriptor mfr_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"ATMEL");

@*2 Product descriptor.

@<Global variables@>=
const S_string_descriptor prod_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"TEL");

@*1 Serial number descriptor.

This one is different in that its content cannot be prepared in compile time,
only in execution time. So, it cannot be stored in program memory.

@d SN_LENGTH 20 /* length of device signature, multiplied by two (because each byte in hex) */

@<Global variables@>=
struct {
  U8 bLength;
  U8 bDescriptorType;
  int wString[SN_LENGTH];
} sn_desc;

@ @d SN_START_ADDRESS 0x0E
@d hex(c) c<10 ? c+'0' : c-10+'A'

@<Fill in |sn_desc| with serial number@>=
sn_desc.bLength = 1 + 1 + SN_LENGTH * 2; /* multiply because Unicode */
sn_desc.bDescriptorType = 0x03;
U8 addr = SN_START_ADDRESS;
for (U8 i = 0; i < SN_LENGTH; i++) {
  U8 c = boot_signature_byte_get(addr);
  if (i & 1) { /* we divide each byte of signature into halves, each of
                  which is represented by a hex number */
    c >>= 4;
    addr++;
  }
  else c &= 0x0F;
  sn_desc.wString[i] = hex(c);
}
