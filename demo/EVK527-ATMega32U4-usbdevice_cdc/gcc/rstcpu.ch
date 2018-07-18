@x
  UHWCON = 1 << UVREGE;
@y
  UHWCON = 1 << UVREGE;

  cli();
  wdt_reset();
  MCUSR &= ~(1<<WDRF);
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  WDTCSR = 0;
@z

@x
  UDCON &= ~(1 << DETACH);
@y
  UDCON &= ~(1 << DETACH);

  while (!(UDINT & (1 << EORSTI))) ;
  UDINT &= ~(1 << EORSTI);
  UENUM = EP0;
  UECONX |= 1 << EPEN;
  UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) | (0 << EPDIR); /* control, OUT */
  UECFG1X = (0 << EPBK0) | (1 << EPSIZE1) + (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 32
    bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
  UDCON |= 1 << RSTCPU;
@z

@x
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    if (UENUM != EP0) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '&'; @+ } /* this
      is needed to ensure that things don't go wrong during PC reboot, when USB reset is
      done multiple times */
    UECONX |= 1 << EPEN;
    UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) | (0 << EPDIR); /* control, OUT */
    UECFG1X = (0 << EPBK0) | (1 << EPSIZE1) + (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 32
      bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
@y
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
@z

@x
#include <avr/pgmspace.h>
@y
#include <avr/pgmspace.h>
#include <avr/wdt.h>
@z
