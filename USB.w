@* Establishing USB connection.

@ \.{USB\_RESET} signal is sent when device is attached and when USB host reboots.

@d EP0_SIZE 32 /* 32 bytes (max for atmega32u4) */

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
    @<Handle {\caps get descriptor device}@>@;
    break;
  case 0x0200: @/
    @<Handle {\caps get descriptor configuration}@>@;
    break;
  case 0x0300: @/
    @<Handle {\caps get descriptor string} (language)@>@;
    break;
  case 0x0300 | SERIAL_NUMBER: @/
    @<Handle {\caps get descriptor string} (serial)@>@;
    break;
  default: @/
    UECONX |= _BV(STALLRQ);
    UEINTX &= ~_BV(RXSTPI);
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

@ @<Handle {\caps set address}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
UEINTX &= ~_BV(TXINI);
UDADDR = wValue & 0x7f;
while (!(UEINTX & 1 << TXINI)) { } /* see \S22.7 in datasheet */
UDADDR |= _BV(ADDEN);

@ @<Handle {\caps get descriptor device}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
if (wLength > sizeof dev_desc) size = sizeof dev_desc;
  /* 18 bytes\footnote*{It is not necessary to implment checking if ZLP from \S5.5.3 of USB
     spec needs to be sent.} */
else size = wLength;
buf = &dev_desc;
while (size) UEDATX = pgm_read_byte(buf++), size--;
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { } 
UEINTX &= ~_BV(RXOUTI);                  

@ @<Handle {\caps get descriptor configuration}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
if (wLength > sizeof conf_desc) size = sizeof conf_desc;
  /* 62 bytes\footnote*{It is not necessary to implment checking if ZLP from \S5.5.3 of USB
     spec needs to be sent.} */
else size = wLength;
buf = &conf_desc;
while (size) {
  U8 nb_byte = 0;
  while (!(UEINTX & _BV(TXINI))) { }
  while (size && nb_byte < EP0_SIZE) UEDATX = pgm_read_byte(buf++), size--, nb_byte++;
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(RXOUTI))) { } 
UEINTX &= ~_BV(RXOUTI);                  

@ @<Handle {\caps get descriptor string} (language)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
if (wLength > sizeof lang_desc) size = sizeof lang_desc;
  /* 4 bytes\footnote*{It is not necessary to implment checking if ZLP from \S5.5.3 of USB
     spec needs to be sent.} */
else size = wLength;
buf = &lang_desc;
while (size) UEDATX = pgm_read_byte(buf++), size--;
UEINTX &= ~_BV(TXINI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ @<Handle {\caps get descriptor string} (serial)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
if (wLength > sizeof sn_desc) size = sizeof sn_desc;
  /* 42 bytes\footnote*{It is not necessary to implment checking if ZLP from \S5.5.3 of USB
     spec needs to be sent.} */
else size = wLength;
buf = &sn_desc;
while (size) {
  U8 nb_byte = 0;
  while (!(UEINTX & _BV(TXINI))) { }
  while (size && nb_byte < EP0_SIZE) UEDATX = *(U8 *) buf++, size--, nb_byte++;
  UEINTX &= ~_BV(TXINI);
}
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);

@ Endpoint 3 (interrupt IN) is not used, but it must be present (for more info
see ``Communication Class notification endpoint notice'' in index).

@d EP1_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of EP1.} */
@d EP2_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of EP2.} */
@d EP3_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of EP3.} */

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
UEINTX &= ~_BV(TXINI);

@ This is data (7 bytes): 80 25 00 00 00 00 08
Just discard the data.
This is the last request after attachment to host.

@<Handle {\caps set line coding}@>=
UEINTX &= ~_BV(RXSTPI);
while (!(UEINTX & _BV(RXOUTI))) { }
UEINTX &= ~_BV(RXOUTI);
UEINTX &= ~_BV(TXINI);

@ {\caps set control line state} requests are sent automatically by the driver when
TTY is opened and closed.

See \S6.2.14 in CDC spec.

@<Handle {\caps set control line state}@>=
wValue = UEDATX | UEDATX << 8;
UEINTX &= ~_BV(RXSTPI);
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

@d SERIAL_NUMBER 1

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
  0, /* no manufacturer */
  0, /* no product */
  SERIAL_NUMBER,
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
    |UECFG0X| of EP3.} */
  EP3_SIZE, @/
@t\2@> 0xFF /* 256 (FIXME: is it `ms'?) */
}

@ @<Initialize element 8 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  IN | 1, /* this corresponds to `1' in `ep1' on picture */
  0x02, /* bulk transfers\footnote\dag{Must correspond to
    |UECFG0X| of EP1.} */
  EP1_SIZE, @/
@t\2@> 0x00 /* not applicable */
}

@ @d OUT (0 << 7)

@<Initialize element 9 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  OUT | 2, /* this corresponds to `2' in `ep2' on picture */
  0x02, /* bulk transfers\footnote\dag{Must correspond to
    |UECFG0X| of EP2.} */
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

It is necessary to transmit serial number.

@<Global variables@>=
struct {
    U8 bLength;
    U8 bDescriptorType;
    int wString;
} const lang_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x04, /* size of this structure */
  0x03, /* string */
@t\2@> 0x0000 /* language id */
};

@*1 Serial number descriptor.

This one is different in that its content cannot be prepared in compile time,
only in execution time. So, it cannot be stored in program memory.

@d DS_LENGTH 10 /* length of device signature */
@d DS_START_ADDRESS 0x0E
@d SN_LENGTH (DS_LENGTH * 2) /* length of serial number (multiply because each value in hex) */

@<Global variables@>=
struct {
  U8 bLength;
  U8 bDescriptorType;
  int wString[SN_LENGTH];
} sn_desc;

@ @d hex(c) c<10 ? c+'0' : c-10+'A'

@<Fill in |sn_desc| with serial number@>=
sn_desc.bLength = sizeof sn_desc;
sn_desc.bDescriptorType = 0x03;
U8 addr = DS_START_ADDRESS;
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
