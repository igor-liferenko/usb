*** 39,53 ****
    while (!connected)
!     if (UEINTX & 1 << RXSTPI)
        @<Process SETUP request@>@;
  
!   PORTD |= 1 << PD0;
!   PORTD |= 1 << PD1;
    while (1) {
!     if (!(PIND & 1 << PD0)) {
        btn = 0x04; /* a */
!       @<Send button@>@;
!       _delay_ms(1000);
!     }
!     if (!(PIND & 1 << PD1)) {
        btn = 0x29; /* ESC */
!       @<Send button@>@;
!       _delay_ms(1000);
      }
--- 38,61 ----
    while (!connected)
!     if (UEINTX & 1 << RXSTPI)
        @<Process SETUP request@>@;
  
!   @<Initialize input pins@>@;
! 
    while (1) {
!     @<Get button@>@;
!     if (btn != 0) {
!       @<Send button@>@;
!       uint16_t prev_button = btn|mod<<8;
!       int timeout = 2000;
!       while (--timeout) {
!         @<Get button@>@;
!         if ((btn|mod<<8) != prev_button) break;
!         _delay_ms(1);
!       }
!       while (1) {
!         @<Get button@>@;
!         if ((btn|mod<<8) != prev_button) break;
!         @<Send button@>@;
!         _delay_ms(50);
!       }
      }
***************
*** 127,129 ****
  
! @ When host is booting, |wLength| is 8 bytes in first request of device descriptor (8 bytes is
  sufficient for first request of device descriptor). If host is operational,
--- 135,137 ----
  
! @ When host is booting, BIOS asks 8 bytes in request of device descriptor (8 bytes is
  sufficient for first request of device descriptor). If host is operational,
***************
*** 137,139 ****
  UEINTX &= ~(1 << RXSTPI);
! send_descriptor(&dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
  
--- 145,147 ----
  UEINTX &= ~(1 << RXSTPI);
! send_descriptor(&dev_desc, wLength < sizeof dev_desc ? wLength : sizeof dev_desc);
