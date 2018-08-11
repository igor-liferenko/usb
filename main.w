If AVR is a usb-rs232 converter, DTR must be used by device on the other end of UART.
If AVR is using usb to pass its own data, DTR may be used directly in program.

Checking DTR in AVR is necessary in order that data will not be transmitted to host until
tty is opened, flushed and DTR enabled.
Flushing is necessary to avoid data buffered by AVR in rs2usb buffer;
data may also be buffered in cdc-acm driver's buffer from previous session
if it was closed until all data was read (?).
Enabling DTR in application is necessary to avoid data being echoed back to AVR
if it starts to transmit until echo was disabled by tty settings (done before
enabling DTR).

To detect DTR change from AVR, check RXSTPI each time while waiting FIFOCON (or TXINI?) (on non-control EP) to become 1 (i.e., when sending data TO host).

prev = UENUM;
UENUM = EP0;
if (UEINTX & 1 << RXSTPI) {
  <read DTR into line_status.DTR>
}
UENUM = prev;
if (line_status.DTR) ...
-----------------------------------------
check if this is the same as in kbd.w and remove:
ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC; /* 32
      bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
  }
}
