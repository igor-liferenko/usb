@x
  UHWCON = 1 << UVREGE;
@y
  UHWCON = 1 << UVREGE;

  cli();
  wdt_reset();
  MCUSR &= ~(1<<WDRF);
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  WDTCSR = 0;

  uint8_t usb_reset = MCUSR & (1 << 5); @+ MCUSR = 0; /* reset as early as possible
    (\S8.0.8 in datasheet) ---~to save some cycles (see below) */
@z

@x
  UDR1 = 'r';
@y
  UDINT &= ~(1 << EORSTI); /* this makes |RSTCPU| work after first reset caused by it */
  UDR1 = 'r';
@z

@x
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  while (!(USBSTA & (1 << VBUS))) ;
  UDCON &= ~(1 << DETACH);
@y
  if (!usb_reset) { /* save some cycles */
    USBCON |= 1 << USBE;
    UDCON |= 1 << RSTCPU; /* it must be enabled only after enabling |USBE| ---~checked
      by checking this bit after setting it */
    USBCON &= ~(1 << FRZCLK);
    USBCON |= 1 << OTGPADE;
    while (!(USBSTA & (1 << VBUS))) ;
    UDCON &= ~(1 << DETACH);
  }
  UECONX |= 1 << EPEN;
  UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) | (0 << EPDIR); /* control, OUT */
  UECFG1X = (0 << EPBK0) | (1 << EPSIZE1) + (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 32
    bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
@z

@x
  UDIEN = (1 << SUSPE) | (1 << EORSTE);
@y
  UDIEN = 1 << SUSPE;
@z

@x
#include <avr/pgmspace.h>
@y
#include <avr/pgmspace.h>
#include <avr/wdt.h>
@z
