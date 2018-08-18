% TODO: re-do send_descriptor as in main.w?
% TODO: do all via wValue, wIndex, wLength as in demo/main.w

\secpagedepth=2 % begin new page only on * % TODO: check via dvidiff if it is used here or after
                                           % \datethis in test.w (with and without kbd.ch)

\font\caps=cmcsc10 at 9pt

@i test.w % \datethis is here (and \let\lheader...)

@* Program. This embedded application source code illustrates how to implement a
keyboard.

@d EP0 0
@d EP1 1
@d EP0_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP0|.} */

@c
@<Header files@>@;
@<Type definitions@>@;
@<Global \null variables@>@;
@<Functions@>@;

volatile int connected = 0;
void main(void)
{
  @<Disable WDT@>@;
  UHWCON = 1 << UVREGE;
  USBCON |= 1 << USBE;
  PLLCSR = 1 << PINDIV | 1 << PLLE; /* FIXME: PLLE must be after PINDIV of may be at once? */
  while (!(PLLCSR & 1 << PLOCK)) ;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  UDIEN = 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  while (!connected) {
    UENUM = EP0; /* it is necessary to do it here because in {\caps set configuration}
      another endpoint is selected */
    if (UEINTX & 1 << RXSTPI) {
      @<Process SETUP request@>@;
    }
  }

  @<Pullup input pins@>@;

  while (1) {
    @<Get button@>@;
    if (btn != 0) {
      @<Send button@>@;
      uint16_t prev_button = btn|mod<<8;
      int timeout = 2000;
      while (--timeout) {
        @<Get button@>@;
        if ((btn|mod<<8) != prev_button) break;
        _delay_ms(1);
      }
      while (1) {
        @<Get button@>@;
        if ((btn|mod<<8) != prev_button) break;
        @<Send button@>@;
        _delay_ms(50);
      }
    }
  }
}

@ @c
ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UENUM = EP0; /* it is necessary because |connected| is set after
      {\caps set configuration}, where another endpoint is selected */
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC; /* 32
      bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
  }
  else {
    @<Reset MCU@>@; /* see \S\resetmcuonhostreboot\ */
  }
}

@ @<Reset MCU@>=
WDTCSR |= 1 << WDCE | 1 << WDE;
WDTCSR = 1 << WDE;
while (1) ;

@ @<Disable WDT@>=
MCUSR = 0x00;
WDTCSR |= 1 << WDCE | 1 << WDE;
WDTCSR = 0x00;

@ The following big switch just dispatches SETUP request.

@<Process SETUP request@>=
uint16_t wValue;
uint16_t wLength;
switch (UEDATX | UEDATX << 8) {
case 0x0500: @/
  @<Handle {\caps set address}@>@;
  break;
case 0x0680: @/
  switch (UEDATX | UEDATX << 8) {
  case 0x0100: @/
    @<Handle {\caps get descriptor device}\null@>@;
    break;
  case 0x0200: @/
    @<Handle {\caps get descriptor configuration}@>@;
    break;
  case 0x0300: @/
    @<Handle {\caps get descriptor string} (language)@>@;
    break;
  case 0x03 << 8 | MANUFACTURER: @/
    @<Handle {\caps get descriptor string} (manufacturer)@>@;
    break;
  case 0x03 << 8 | PRODUCT: @/
    @<Handle {\caps get descriptor string} (product)@>@;
    break;
  case 0x0600: @/
    @<Handle {\caps get descriptor device qualifier}@>@;
    break;
  }
  break;
case 0x0681: @/
  @<Handle {\caps get descriptor hid}@>@;
  @<Finish connection@>@;
  break;
case 0x0900: @/
  @<Handle {\caps set configuration}@>@;
  break;
case 0x0a21: @/
  @<Handle {\caps set idle}@>@;
  break;
}

@ No OUT packet arrives after SETUP packet, because there is no DATA stage
in this request. IN packet arrives after SETUP packet, and we get ready to
send a ZLP in advance.

@<Handle {\caps set address}@>=
wValue = UEDATX | UEDATX << 8;
UDADDR = wValue & 0x7F;
UEINTX &= ~(1 << RXSTPI);
UEINTX &= ~(1 << TXINI); /* STATUS stage */
while (!(UEINTX & (1 << TXINI))) ; /* wait until ZLP, prepared by previous command, is
            sent to host\footnote{$\sharp$}{According to \S22.7 of the datasheet,
            firmware must send ZLP in the STATUS stage before enabling the new address.
            The reason is that the request started by using zero address, and all the stages of the
            request must use the same address.
            Otherwise STATUS stage will not complete, and thus set address request will not
            succeed. We can determine when ZLP is sent by receiving the ACK, which sets TXINI to 1.
            See ``Control write (by host)'' in table of contents for the picture (note that DATA
            stage is absent).} */
UDADDR |= 1 << ADDEN;

@ When host is booting, BIOS asks 8 bytes in request of device descriptor (8 bytes is
sufficient for first request of device descriptor). If host is operational,
|wLength| is 64 bytes in first request of device descriptor.
It is OK if we transfer less than the requested amount. But if we try to
transfer more, device will hang.

If we send more than requested by host, it does not send OUT packet to initiate STATUS stage.

@<Handle {\caps get descriptor device}\null@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
send_descriptor(&dev_desc, wLength < sizeof dev_desc ? wLength : sizeof dev_desc);

@ First request is 9 bytes, second is according to length given in response to first request.

@<Handle {\caps get descriptor configuration}@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
send_descriptor(&conf_desc, wLength);

@ @<Handle {\caps get descriptor string} (language)@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(lang_desc, sizeof lang_desc);

@ @<Handle {\caps get descriptor string} (manufacturer)@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(&mfr_desc, pgm_read_byte(&mfr_desc.bLength));

@ @<Handle {\caps get descriptor string} (product)@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(&prod_desc, pgm_read_byte(&prod_desc.bLength));

@ A high-speed capable device that has different device information for full-speed and high-speed
must have a Device Qualifier Descriptor. For example, if the device is currently operating at
full-speed, the Device Qualifier returns information about how it would operate at high-speed and
vice-versa. So as this device is full-speed, it tells the host not to request
device information for high-speed by using ``protocol stall'' (this stall
does not indicate an error with the device, it serves merely as a means of
extending USB requests).

This STALL condition is automatically cleared on the receipt of the
next SETUP token.

USB\S8.5.3.4, datasheet\S22.11.

@<Handle {\caps get descriptor device qualifier}@>=
UEINTX &= ~(1 << RXSTPI);
UECONX |= 1 << STALLRQ; /* return STALL in response to IN token of the DATA stage */

@ @<Handle {\caps get descriptor hid}@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(hid_report_descriptor, sizeof hid_report_descriptor);

@ @<Finish connection@>=
connected = 1;
UENUM = EP1;

@ @<Handle {\caps set configuration}@>=
UEINTX &= ~(1 << RXSTPI);
UEINTX &= ~(1 << TXINI); /* STATUS stage */
UENUM = EP1;
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR; /* interrupt\footnote\dag
  {Must correspond to IN endpoint description in |@<Initialize element 4...@>|.}, IN */
UECFG1X = 1 << ALLOC; /* 8 bytes\footnote
  {\dag\dag}{Must correspond to IN endpoint description in |hid_report_descriptor|.} */
UERST = 1 << EP1, UERST = 0; /* FIXME: is this needed? */

@ @<Handle {\caps set idle}@>=
UEINTX &= ~(1 << RXSTPI);
UEINTX &= ~(1 << TXINI); /* STATUS stage */

@ See datasheet \S22.12.2.

When previous packet was sent, TXINI becomes `1'. After TXINI becomes `1', new data may be written
to UEDATX. With TXINI the logic is the same as with UDRE, and UEDATX is like UDR.

TODO: if |size < wLength|, send empty packet if |size % EP0_SIZE == 0|.
add third argument to this function - emp
@^TODO@>

@<Functions@>=
void send_descriptor(const void *buf, int size)
{
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE)
        break;
      UEDATX = pgm_read_byte(buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI); /* this is suspicious, because it will send empty packet,
      and if nakouti comes before rxouti, we txini is already set, but nothing more
      must be transmitted (because nakouti was set), but an empty packet will be transmitted
      (because the following condition will be true only when next packet arrives - this
      is when RXOUTI is set); a check is required if nakouti comes before rxouti - see
      test in \S\nakoutibeforerxouti\ */
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
}

@i control-endpoint-management.w

@i IN-endpoint-management.w

@* USB stack.

@*1 Device descriptor.

TODO: find what prefixes mean in names of variables (i.e., `b', `bcd', ...)

@d MANUFACTURER 0x01
@d PRODUCT 0x02
@d NOT_USED 0x00

@<Global \null variables@>=
struct {
  uint8_t      bLength;
  uint8_t      bDescriptorType;
  uint16_t     bcdUSB; /* version */
  uint8_t      bDeviceClass; /* class code assigned by the USB */
  uint8_t      bDeviceSubClass; /* sub-class code assigned by the USB */
  uint8_t      bDeviceProtocol; /* protocol code assigned by the USB */
  uint8_t      bMaxPacketSize0; /* max packet size for EP0 */
  uint16_t     idVendor;
  uint16_t     idProduct;
  uint16_t     bcdDevice; /* device release number */
  uint8_t      iManufacturer; /* index of manu. string descriptor */
  uint8_t      iProduct; /* index of prod. string descriptor */
  uint8_t      iSerialNumber; /* index of S.N. string descriptor */
  uint8_t      bNumConfigurations;
} const dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  18, /* size of this structure */
  0x01, /* device */
  0x0200, /* USB 2.0 */
  0, /* no class */
  0, /* no subclass */
  0, @/
  EP0_SIZE, @/
  0x03EB, /* VID (Atmel) */
  0x2015, /* PID (HID keyboard) */
  0x1000, /* device revision */
  MANUFACTURER, /* (\.{Mfr} in \.{kern.log}) */
  PRODUCT, /* (\.{Product} in \.{kern.log}) */
  NOT_USED, /* (\.{SerialNumber} in \.{kern.log}) */
@t\2@> 1 /* one configuration for this device */
};

@*1 Configuration descriptor.

$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=kbd-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$

@<Type definitions@>=
typedef struct {
   @<Configuration header descriptor@> @,@,@! el1;
   @<Interface descriptor@> @,@,@! el2;
   @<HID configuration descriptor@> @,@,@! el3;
   @<Endpoint descriptor@> @,@,@! el4;
} S_configuration_descriptor;

@ @<Global \null variables@>=
@<Global variables used in configuration descriptor@>@;
const S_configuration_descriptor conf_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize element 1 ...@>, @/
  @<Initialize element 2 ...@>, @/
  @<Initialize element 3 ...@>, @/
@t\2@> @<Initialize element 4 ...@> @/
};

@*2 Configuration header descriptor.

@<Configuration header descriptor@>=
struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint16_t     wTotalLength;
   uint8_t      bNumInterfaces;
   uint8_t      bConfigurationValue; /* number between 1 and |bNumConfigurations|, for
     each configuration\footnote\dag{For some reason
     configurations start numbering with `1', and interfaces and altsettings with `0'.} */
   uint8_t      iConfiguration; /* index of string descriptor */
   uint8_t      bmAttibutes;
   uint8_t      MaxPower;
}

@ @<Initialize element 1 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x02, /* configuration descriptor */
  sizeof (S_configuration_descriptor), @/
  1, /* one interface in this configuration */
  1, /* this corresponds to `1' in `cfg1' on picture */
  0, /* no string descriptor */
  0x80, /* device is powered from bus */
@t\2@> 0x32 /* device uses 100mA */
}

@*2 Interface descriptor.

@<Interface descriptor@>=
struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint8_t      bInterfaceNumber; /* number between 0 and |bNumInterfaces-1|, for
                                     each interface */
   uint8_t      bAlternativeSetting; /* number starting from 0, for each interface */
   uint8_t      bNumEndpoints; /* number of EP except EP 0 */
   uint8_t      bInterfaceClass; /* class code assigned by the USB */
   uint8_t      bInterfaceSubClass; /* sub-class code assigned by the USB */
   uint8_t      bInterfaceProtocol; /* protocol code assigned by the USB */
   uint8_t      iInterface; /* index of string descriptor */
}

@ |bInterfaceSubClass| signifies device type (non-bootable or bootable).

|bInterfaceProtocol| is used if device is determined as bootable. It signifies
standard protocol which the device supports (user-defined, keyboard or mouse).

@<Initialize element 2 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x04, /* interface descriptor */
  0, /* this corresponds to `0' in `if0' on picture */
  0, /* this corresponds to `0' in `alt0' on picture */
  1, /* one endpoint is used */
  0x03, /* HID */
  0, /* non-bootable */
  0, /* not used */
@t\2@> 0 /* no string descriptor */
}

@*2 HID configuration descriptor.

@<HID configuration descriptor@>=
struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bReportDescriptorType;
  uint16_t wReportDescriptorLength;
}

@ @<Initialize element 3 in configuration descriptor@>= { @t\1@> @/
  9, /* size of this structure */
  0x21, /* HID */
  0x0100, /* HID version 1.0 */
  0x00, /* no localization */
  0x01, /* one descriptor for this device */
  0x22, /* HID report (value for |bDescriptorType| in {\caps get descriptor hid}) */
@t\2@> sizeof hid_report_descriptor @/
}

@*2 Endpoint descriptor.

@<Endpoint descriptor@>=
struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bEndpointAddress;
  uint8_t bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t bInterval; /* interval for polling EP by host to determine if data is available (ms-1) */
}

@ @d IN (1 << 7)

@<Initialize element 4 in configuration descriptor@>= { @t\1@> @/
  7, /* size of this structure */
  0x05, /* endpoint */
  IN | 1, /* this corresponds to `1' in `ep1' on picture */
  0x03, /* transfers via interrupts\footnote\dag{Must correspond to
    |UECFG0X| of |EP1|.} */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}

@*1 HID report descriptor.

The usual format for keyboard reports is the following byte array:

\centerline{modifier, reserved, Key1, Key2, Key3, Key4, Key5, Key6}

When you press the letter `a' on a USB keyboard, the following report will be sent in
response to an IN interrupt request:

\centerline{|0x00|, |0x00|, |0x04|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

\noindent This `|0x04|' value is the Keycode for the letter `a'.

After releasing the key, the following report will be sent:

\centerline{|0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

\noindent An array of zeros means nothing is being pressed.

For an uppercase `A', the report will also need to contain a `Left Shift' modifier.
The modifier byte is actually a bitmap, which means that each bit corresponds to one key:

bit 0: left control\par
bit 1: left shift\par
bit 2: left alt\par
bit 3: left GUI (Win/Apple/Meta key)\par
bit 4: right control\par
bit 5: right shift\par
bit 6: right alt\par
bit 7: right GUI\par

\noindent With left shift pressed, out report will look like that:

\centerline{|0x02|, |0x00|, |0x04|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

{\bf Note:} This report descriptor was prepared in ``HID descriptor tool'' (it works
in \.{wine}; start the executable from the same folder to which it was unpacked).

@<Global variables ...@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x05, 0x01, @t\hskip10pt@> // \.{USAGE\_PAGE (Generic Desktop)}
  0x09, 0x06, @t\hskip10pt@> // \.{USAGE (Keyboard)}
  0xa1, 0x01, @t\hskip10pt@> // \.{COLLECTION (Application)}
  0x05, 0x07, @t\hskip21pt@> //   \.{USAGE\_PAGE (Keyboard)}
  0x75, 0x01, @t\hskip21pt@> //   \.{REPORT\_SIZE (1)}
  0x95, 0x08, @t\hskip21pt@> //   \.{REPORT\_COUNT (8)}
  0x19, 0xe0, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Keyboard LeftControl)}
  0x29, 0xe7, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Right GUI)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x01, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (1)}
  0x81, 0x02, @t\hskip21pt@> //   \.{INPUT (Data,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x01, @t\hskip21pt@> //   \.{REPORT\_COUNT (1)}
  0x81, 0x03, @t\hskip21pt@> //   \.{INPUT (Cnst,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x06, @t\hskip21pt@> //   \.{REPORT\_COUNT (6)}
  0x19, 0x00, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Reserved (no event indicated))}
  0x29, 0x65, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Application)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x65, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (101)}
  0x81, 0x00, @t\hskip21pt@> //   \.{INPUT (Data,Ary,Abs)}
@t\2@> 0xc0   @t\hskip36pt@> // \.{END\_COLLECTION}
};

@ Key press, then key release.

@<Send button@>=
while (!(UEINTX & (1 << TXINI))) ;
UEINTX &= ~(1 << TXINI);
UEDATX = mod;
UEDATX = 0;
UEDATX = btn;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEINTX &= ~(1 << FIFOCON);

while (!(UEINTX & (1 << TXINI))) ;
UEINTX &= ~(1 << TXINI);
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEDATX = 0;
UEINTX &= ~(1 << FIFOCON);

@*1 Language descriptor.

This is necessary to transmit manufacturer and product.

@<Global \null variables@>=
const uint8_t lang_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x04, /* size */
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

@^GCC-specific@>

@s S_string_descriptor int

@<Type definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  int16_t wString[];
} S_string_descriptor;

#define STR_DESC(str) @,@,@,@, {@, 1 + 1 + sizeof str - 2, 0x03, str @t\hskip1pt@>}

@*2 Manufacturer descriptor.

@<Global \null variables@>=
const S_string_descriptor mfr_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"ATMEL");

@*2 Product descriptor.

@<Global \null variables@>=
const S_string_descriptor prod_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"AVR USB HID DEMO");

@* Matrix.

$$\hbox to6cm{\vbox to6.59cm{\vfil\special{psfile=keymap.eps
  clip llx=0 lly=0 urx=321 ury=353 rwi=1700}}\hfil}$$

This is the working principle:
$$\hbox to7cm{\vbox to4.2cm{\vfil\special{psfile=keypad.eps
  clip llx=0 lly=0 urx=240 ury=144 rwi=1984}}\hfil}$$

A is input and  C1 ... Cn are outputs.
We "turn on" one of C1, C2, ... Cn at a time by connecting it to ground inside the chip
(i.e., setting it to logic zero).
Other pins of C1, C2, ... Cn are not connected anywhere at that time.
The current will always flow into the pin which is connected to ground.
The current has to flow into your transmitter for the receiver to be able to tell it's a zero.
Now when the switch connected to this output pin is pressed, the input A
is pulled to ground through the switch, and its state becomes zero.
Pressing other switches doesn't change anything, since their other pins
are not connected to ground. When we want to read another switch, we
change the output pin which is connected to ground, so that always
just one of them is set like that.

To set output pin, do this:
|DDRx.y = 1|.
To unset output pin, do this;
|DDRx.y = 0|.

@ This is how keypad is connected:

\chardef\ttv='174 % vertical line
$$\vbox{\halign{\tt#\cr
+-----------+ \cr
{\ttv} 1 {\ttv} 2 {\ttv} 3 {\ttv} \cr
{\ttv} 4 {\ttv} 5 {\ttv} 6 {\ttv} \cr
{\ttv} 7 {\ttv} 8 {\ttv} 9 {\ttv} \cr
{\ttv} * {\ttv} 0 {\ttv} \char`#\ {\ttv} \cr
+-----------+ \cr
\ \ \ \ \ {\ttv} {\ttv} \cr
\ \ \ \ \ {\ttv} {\ttv} \cr
\ \ +-------+ \cr
\ \ {\ttv}1234567{\ttv} \cr
\ \ +-------+ \cr
}}$$

Where 1,2,3,4 are |PB4|,|PB5|,|PE6|,|PD7| and 5,6,7 are |PF4|,|PF5|,|PF6|.

@ @<Pullup input pins@>=
PORTB |= 1 << PB4 | 1 << PB5;
PORTE |= 1 << PE6;
PORTD |= 1 << PD7;

@ @<Global \null variables@>=
uint8_t btn = 0, mod = 0;

@
% NOTE: use index into an array of Pxn if pins in "for" are not consequtive:
% int a[3] = { PF3, PD4, PB5 }; ... for (int i = 0, ... DDRF |= 1 << a[i]; ... switch (a[i]) ...

% NOTE: use array of indexes to separate bits if pin numbers in "switch" collide:
% int b[256] = {0};
% if (~PINB & 1 << PB4) b[0xB4] = 1 << 0; ... if ... b[0xB5] = 1 << 1; ... b[0xE6] = 1 << 2; ...
% switch (b[0xB4] | ...) ... case b[0xB4]: ...
% (here # in woven output will represent P)

@<Get button@>=
    for (int i = PF4, done = 0; i <= PF6 && !done; i++) {
      DDRF |= 1 << i;
      @<Eliminate capacitance@>@;
      switch (~PINB & (1 << PB4 | 1 << PB5) | ~PINE & 1 << PE6 | ~PIND & 1 << PD7) {
      case 1 << PB4:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x1e; @+ break;
        case PF5: mod = 0; @+ btn = 0x1f; @+ break;
        case PF6: mod = 0; @+ btn = 0x20; @+ break;
        }
        done = 1;
        break;
      case 1 << PB5:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x21; @+ break;
        case PF5: mod = 0; @+ btn = 0x22; @+ break;
        case PF6: mod = 0; @+ btn = 0x23; @+ break;
        }
        done = 1;
        break;
      case 1 << PE6:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x24; @+ break;
        case PF5: mod = 0; @+ btn = 0x25; @+ break;
        case PF6: mod = 0; @+ btn = 0x26; @+ break;
        }
        done = 1;
        break;
      case 1 << PD7:
        switch (i) {
        case PF4: mod = 0x02; @+ btn = 0x25; @+ break;
        case PF5: mod = 0x00; @+ btn = 0x27; @+ break;
        case PF6: mod = 0x02; @+ btn = 0x20; @+ break;
        }
        done = 1;
        break;
      default: @/
        btn = 0; @+ mod = 0;
      }
      DDRF &= ~(1 << i);
    }

@ Delay to eliminate capacitance on the wire which may be open-ended on
the side of input pin (i.e., when button is not pressed), and capacitance
on the longer wire (i.e., when button is pressed).

To adjust the number of no-ops, remove all no-ops from here,
then do this: 1) If symbol(s) will appear by themselves,
add one no-op. Repeat until this does not happen. 2) If
symbol does not appear after pressing a key, add one no-op.
Repeat until this does not happen.

@d nop() __asm__ __volatile__ ("nop")

@<Eliminate capacitance@>=
nop();
nop();
nop();
nop();
nop();

@* Headers.
\secpagedepth=1 % index on current page

@<Header files@>=
#include <avr/boot.h> /* |boot_signature_byte_get| */
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h> /* |wdt_reset| */
#include <stddef.h> /* |NULL| */
#define F_CPU 16000000UL
#include <util/delay.h>

@* Index.
