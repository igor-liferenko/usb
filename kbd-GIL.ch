*** /tmp/gbcyOh_kbd.w	2018-07-30 14:18:44.944534248 +0700
--- /tmp/wXICNh_kbd.w	2018-07-30 14:18:44.944534248 +0700
***************
*** 23,28 ****
  {
- /* TODO: ensure that all is done via `\.{\char'174=}', because MCU may be reset via RSTCPU,
-  when usb stuff remains active (and cmp with original asm.S) */
    UHWCON |= 1 << UVREGE;
  
    PLLCSR = (1 << PINDIV) | (1 << PLLE);
--- 23,28 ----
  {
    UHWCON |= 1 << UVREGE;
  
+   UDCON &= ~(1 << RSTCPU); /* see \S\cpuresetonlyonhostreboot\ */
+ 
    PLLCSR = (1 << PINDIV) | (1 << PLLE);
***************
*** 35,37 ****
    UDCON &= ~(1 << DETACH);
-   UDCON &= ~(1 << RSTCPU); /* see \S\cpuresetonlyonhostreboot\ */
  
--- 35,36 ----
***************
*** 39,53 ****
    while (!connected)
!     if (UEINTX & 1 << RXSTPI)
        @<Process SETUP request@>@;
  
!   PORTD |= 1 << PD0;
!   PORTD |= 1 << PD1;
    while (1) {
!     if (!(PIND & 1 << PD0)) {
!       @<Press button `a'@>@;
!       _delay_ms(1000);
!     }
!     if (!(PIND & 1 << PD1)) {
!       @<Press button `ESC'@>@;
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
  
***************
*** 515,545 ****
  
! @ @<Press button `a'@>=
        UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0x04;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEINTX &= ~(1 << TXINI);
!       UEINTX &= ~(1 << FIFOCON);
!       while (!(UEINTX & 1 << TXINI)) ; /* wait until previous packet will be sent, then prepare
!         new packet to be sent when following IN request arrives (for key release) */
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0;
!       UEINTX &= ~(1 << TXINI);
!       UEINTX &= ~(1 << FIFOCON);
!       while (!(UEINTX & 1 << TXINI)) ; /* wait until previous packet will be sent */
! 
! @ @<Press button `ESC'@>=
!       UEDATX = 0;
!       UEDATX = 0;
!       UEDATX = 0x29;
        UEDATX = 0;
--- 522,527 ----
  
! @ @<Send button@>=
!       UEDATX = mod;
        UEDATX = 0;
!       UEDATX = btn;
        UEDATX = 0;
***************
*** 567,569 ****
  
! This is necessary to transmit serial number.
  
--- 549,551 ----
  
! This is necessary to transmit manufacturer, product and serial number.
  
***************
*** 658,659 ****
--- 641,693 ----
  
+ @* Matrix.
+ 
+ @ @<Global \null variables@>=
+ uint8_t btn = 0, mod = 0;
+ 
+ @ @<Initialize input pins@>=
+ PORTB |= 1 << PB4 | 1 << PB5 | 1 << PB6 | 1 << PB7;
+ 
+ @ @<Get button@>=
+     for (int i = PD0, done = 0; i <= PD2 && !done; i++) {
+       DDRD |= 1 << i;
+       while (~PINB & 0xF0) ;
+       switch (~PINB & 0xF0) {
+       case 1 << PB4:
+         switch (i) {
+         case PD0: mod = 0; @+ btn = 0x1e; @+ break;
+         case PD1: mod = 0; @+ btn = 0x1f; @+ break; 
+         case PD2: mod = 0; @+ btn = 0x20; @+ break;         
+         }
+         done = 1;
+         break;
+       case 1 << PB5:
+         switch (i) {
+         case PD0: mod = 0; @+ btn = 0x21; @+ break;
+         case PD1: mod = 0; @+ btn = 0x22; @+ break; 
+         case PD2: mod = 0; @+ btn = 0x23; @+ break;         
+         }
+         done = 1;
+         break;
+       case 1 << PB6:
+         switch (i) {
+         case PD0: mod = 0; @+ btn = 0x24; @+ break;
+         case PD1: mod = 0; @+ btn = 0x25; @+ break;
+         case PD2: mod = 0; @+ btn = 0x26; @+ break; 
+         }
+         done = 1;
+         break;
+       case 1 << PB7:
+         switch (i) {
+         case PD0: mod = 0x02; @+ btn = 0x25; @+ break;
+         case PD1: mod = 0x00; @+ btn = 0x27; @+ break; 
+         case PD2: mod = 0x02; @+ btn = 0x20; @+ break;         
+         }
+         done = 1;
+         break;
+       default: @/
+         btn = 0; @+ mod = 0;
+       }
+       DDRD &= ~(1 << i);
+     }
+ 
  @* Headers.
