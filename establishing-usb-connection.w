@* Establishing USB connection.

@<Global variables@>=
volatile int connected = 0;

@ @d EP0 0 /* selected by default */
@d EP0_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP0|.}
                  (max for atmega32u4) */

@<Create ISR for connecting to USB host@>=
ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI); /* for the interrupt handler to be called for next USB\_RESET */
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
    UECFG1X |= 1 << ALLOC;
  }
  else {
    @<Reset MCU@>@;
  }
}

@ Used in USB\_RESET interrupt handler.
Reset is used to go to beginning of connection loop (because we cannot
use \&{goto} from within interrupt handler). Watchdog reset is used because
in atmega32u4 there is no simpler way to reset MCU.

@<Reset MCU@>=
WDTCSR |= 1 << WDCE | 1 << WDE; /* allow to enable WDT */
WDTCSR = 1 << WDE; /* enable WDT */
while (1) ;

@ When reset is done via watchdog, WDRF (WatchDog Reset Flag) is set in MCUSR register.
WDE (WatchDog system reset Enable) is always set in WDTCSR when WDRF is set. It
is necessary to clear WDE to stop MCU from eternal resetting:
on MCU start we always clear |WDRF| and WDE
(nothing will change if they are not set).
To avoid unintentional changes of WDE, a special write procedure must be followed
to change the WDE bit. To clear WDE, WDRF must be cleared first.

Datasheet says that |WDE| is always set to one when |WDRF| is set to one,
but it does not say if |WDE| is always set to zero when |WDRF| is not set
(by default it is zero).
So we must always clear |WDE| independent of |WDRF|.

This should be done right at the beginning of |main|, in order to be in
time before WDT is triggered.
We don't call \\{wdt\_reset} because initialization code,
that \.{avr-gcc} adds, has enough time to execute before watchdog
timer (16ms in this program) expires:

$$\vbox{\halign{\tt#\cr
  eor r1, r1 (1 cycle)\cr
  out 0x3f, r1 (1 cycle)\cr
  ldi r28, 0xFF (1 cycle)\cr
  ldi r29, 0x0A (1 cycle)\cr
  out 0x3e, r29 (1 cycle)\cr
  out 0x3d, r28 (1 cycle)\cr
  call <main> (4 cycles)\cr
}}$$

At 16MHz each cycle is 62.5 nanoseconds, so it is 7 instructions,
taking 10 cycles, multiplied by 62.5 is 625 nanoseconds.

What the above code does: zero r1 register, clear SREG, initialize program stack
(to the stack processor writes addresses for returning from subroutines and interrupt
handlers). To the stack pointer is written address of last cell of RAM.

Note, that ns is $10^{-9}$, $\mu s$ is $10^{-6}$ and ms is $10^{-3}$.

@<Disable WDT@>=
if (MCUSR & 1 << WDRF) /* takes 2 instructions if |WDRF| is set to one:
    \.{in} (1 cycle),
    \.{sbrs} (2 cycles), which is 62.5*3 = 187.5 nanoseconds
    more, but still within 16ms; and it takes 5 instructions if |WDRF|
    is not set: \.{in} (1 cycle), \.{sbrs} (2 cycles), \.{rjmp} (2 cycles),
    which is 62.5*5 = 312.5 ns more, but still within 16ms */
  MCUSR &= ~(1 << WDRF); /* takes 3 instructions: \.{in} (1 cycle),
    \.{andi} (1 cycle), \.{out} (1 cycle), which is 62.5*3 = 187.5 nanoseconds
    more, but still within 16ms */
if (WDTCSR & 1 << WDE) { /* takes 2 instructions: \.{in} (1 cycle),
    \.{sbrs} (2 cycles), which is 62.5*3 = 187.5 nanoseconds
    more, but still within 16ms */
  WDTCSR |= 1 << WDCE; /* allow to disable WDT (\.{lds} (2 cycles), \.{ori}
    (1 cycle), \.{sts} (2 cycles)), which is 62.5*5 = 312.5 ns more, but
    still within 16ms) */
  WDTCSR = 0x00; /* disable WDT (\.{sts} (2 cycles), which is 62.5*2 = 125 ns more,
    but still within 16ms)\footnote*{`\&=' must not be used here, because
    the following instructions will be used: \.{lds} (2 cycles),
    \.{andi} (1 cycle), \.{sts} (2 cycles), but according to datasheet \S8.2
    this must not exceed 4 cycles, whereas with `=' at most the
    following instructions are used: \.{ldi} (1 cycle) and \.{sts} (2 cycles),
    which is within 4 cycles.} */
}

@ @<Connect to USB host (by calling |sei|)@>=
  UHWCON |= 1 << UVREGE;
  USBCON |= 1 << USBE;
  PLLCSR = 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & 1 << PLOCK)) ;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH); /* attach after we prepared interrupts, because
    USB\_RESET will arrive only after attach, and before it arrives, all interrupts
    must be already set up; also, there is no need to detect when VBUS becomes
    high ---~USB\_RESET can arrive only after VBUS is operational anyway, and
    USB\_RESET is detected via interrupt */

  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      @<Process SETUP request@>@;

@ @<Global variables@>=
U16 wValue;
U16 wIndex;
U16 wLength;

@ The following big switch just dispatches SETUP request.

@<Process SETUP request@>=
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
  case 0x03 << 8 | SERIAL_NUMBER: @/
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
}

@ No OUT packet arrives after SETUP packet, because there is no DATA stage
in this request. IN packet arrives after SETUP packet, and we get ready to
send a ZLP in advance.

@<Handle {\caps set address}@>=
wValue = UEDATX | UEDATX << 8;
UDADDR = wValue & 0x7F;
UEINTX &= ~(1 << RXSTPI);
UEINTX &= ~(1 << TXINI); /* STATUS stage */
while (!(UEINTX & 1 << TXINI)) ; /* wait until ZLP, prepared by previous command, is
  sent to host\footnote{$\sharp$}{According to \S22.7 of the datasheet,
  firmware must send ZLP in the STATUS stage before enabling the new address.
  The reason is that the request started by using zero address, and all the stages of the
  request must use the same address.
  Otherwise STATUS stage will not complete, and thus set address request will not
  succeed. We can determine when ZLP is sent by receiving the ACK, which sets TXINI to 1.
  See ``Control write (by host)'' in table of contents for the picture (note that DATA
  stage is absent).} */
UDADDR |= 1 << ADDEN;

@ When host is booting, BIOS asks 8 bytes in first request of device descriptor (8 bytes is
sufficient for first request of device descriptor). If host is operational,
|wLength| is 64 bytes in first request of device descriptor.
It is OK if we transfer less than the requested amount. But if we try to
transfer more, host does not send OUT packet to initiate STATUS stage.

@<Handle {\caps get descriptor device}\null@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = sizeof dev_desc;
buf = &dev_desc;
@<Send descriptor@>@;

@ A high-speed capable device that has different device information for full-speed and high-speed
must have a Device Qualifier Descriptor. For example, if the device is currently operating at
full-speed, the Device Qualifier returns information about how it would operate at high-speed and
vice-versa. So as this device is full-speed, it tells the host not to request
device information for high-speed by using ``protocol stall'' (such stall
does not indicate an error with the device ---~it serves as a means of
extending USB requests).

The host sends an IN token to the control pipe to initiate the DATA stage.

$$\hbox to10.93cm{\vbox to5.15055555555556cm{\vfil\special{%
  psfile=../usb/stall-control-read-with-data-stage.eps
  clip llx=0 lly=0 urx=310 ury=146 rwi=3100}}\hfil}$$

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
size = sizeof conf_desc;
buf = &conf_desc;
@<Send descriptor@>@;

@ @<Handle {\caps get descriptor string} (language)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = sizeof lang_desc;
buf = lang_desc;
@<Send descriptor@>@;

@ @<Handle {\caps get descriptor string} (manufacturer)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = pgm_read_byte(&mfr_desc.bLength);
buf = &mfr_desc;
@<Send descriptor@>@;

@ @<Handle {\caps get descriptor string} (product)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = pgm_read_byte(&prod_desc.bLength);
buf = &prod_desc;
@<Send descriptor@>@;

@ Here we handle one case when data (serial number) needs to be transmitted from memory,
not from program.

@<Handle {\caps get descriptor string} (serial)@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
size = 1 + 1 + SN_LENGTH * 2; /* multiply because Unicode */
@<Get serial number@>@;
buf = &sn_desc;
from_program = 0;
@<Send descriptor@>@;

@ Interrupt IN endpoint is not used, but it must be present (see first section of
``Configuration descriptor'' chapter).

FIXME: move EP3 below EP1 and EP2?

@d EP1 1
@d EP2 2
@d EP3 3
@d EP1_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP1|.} */
@d EP2_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP2|.} */
@d EP3_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP3|.} */

@<Handle {\caps set configuration}@>=
UEINTX &= ~(1 << RXSTPI);

UENUM = EP3;
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR; /* interrupt\footnote\dag{Must
  correspond to |@<Initialize element 6 ...@>|.}, IN */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP3_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = EP1;
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1 | 1 << EPDIR; /* bulk\footnote\dag{Must
  correspond to |@<Initialize element 8 ...@>|.}, IN */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP1_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = EP2;
UECONX |= 1 << EPEN;
UECFG0X = 1 << EPTYPE1; /* bulk\footnote\dag{Must
  correspond to |@<Initialize element 9 ...@>|.}, OUT */
UECFG1X = 1 << EPSIZE1; /* 32 bytes\footnote\ddag{Must correspond to |EP2_SIZE|.} */
UECFG1X |= 1 << ALLOC;

UENUM = EP0; /* restore for further setup requests */
UEINTX &= ~(1 << TXINI); /* STATUS stage */

@ Just discard the data.
This is the last request after attachment to host.

@<Handle {\caps set line coding}@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UEINTX & 1 << RXOUTI)) ; /* wait for DATA stage */
UEINTX &= ~(1 << RXOUTI);
UEINTX &= ~(1 << TXINI); /* STATUS stage */
connected = 1;

@ @<Global variables@>=
U16 size;
const void *buf;
U8 from_program = 1; /* serial number is transmitted last, so this can be set only once */
U8 empty_packet;

@ Transmit data and empty packet (if necessary) and wait for STATUS stage.

On control endpoint by clearing TXINI (in addition to making it possible to
know when bank will be free again) we say that when next IN token arrives,
data must be sent and endpoint bank cleared. When data was sent, TXINI becomes `1'.
After TXINI becomes `1', new data may be written to UEDATX.\footnote*{The
difference of clearing TXINI for control and non-control endpoint is that
on control endpoint clearing TXINI also sends the packet and clears the endpoint bank.
On non-control endpoints there is a possibility to have double bank, so another
mechanism is used.}

@<Send descriptor@>=
empty_packet = 0;
if (size < wLength && size % EP0_SIZE == 0)
  empty_packet = 1; /* indicate to the host that no more data will follow (USB\S5.5.3) */
if (size > wLength)
  size = wLength; /* never send more than requested */
while (size != 0) {
  while (!(UEINTX & 1 << TXINI)) ;
  U8 nb_byte = 0;
  while (size != 0) {
    if (nb_byte++ == EP0_SIZE)
      break;
    UEDATX = from_program ? pgm_read_byte(buf++) : *(U8 *) buf++;
    size--;
  }
  UEINTX &= ~(1 << TXINI);
}
if (empty_packet) {
  while (!(UEINTX & 1 << TXINI)) ;
  UEINTX &= ~(1 << TXINI);
}
while (!(UEINTX & 1 << RXOUTI)) ; /* wait for STATUS stage */
UEINTX &= ~(1 << RXOUTI);
