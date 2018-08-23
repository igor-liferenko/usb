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
!     if (UEINTX & (1 << RXSTPI))
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
*** 171,173 ****
  FIXME: it is not clear how |STALLRQ| works, because it works before clearing |RXSTPI|, and
! it works after
  @^FIXME@>
--- 179,182 ----
  FIXME: it is not clear how |STALLRQ| works, because it works before clearing |RXSTPI|, and
! it works after; but according to test in \S\rxstpiautoack, |RXSTPI| is not automatically
! acknowledged...
  @^FIXME@>
***************
*** 183,185 ****
  @ @<Finish connection@>=
! connected = 1; /* in contrast with \.{test.w}, it must be before switching from |EP0| */
  UENUM = EP1;
--- 192,194 ----
  @ @<Finish connection@>=
! connected = 1; /* in contrast with \S\uenumtozero, it must be before switching from |EP0| */
  UENUM = EP1;
***************
*** 190,193 ****
    {\dag\dag}{Must correspond to IN endpoint description in |hid_report_descriptor|.} */
- while (!(UESTA0X & (1 << CFGOK))) ; /* TODO: test with led if it is necessary (create
-   a test for this in test.w, like the first test for control endpoint) */
  
--- 199,200 ----
***************
*** 197,202 ****
  
! @ This request is used to set idle rate for reports. Duration 0 (first byte of wValue)
! means that host lets the device send reports only when it needs.
! 
! @<Handle {\caps set idle}@>=
  UEINTX &= ~(1 << RXSTPI);
--- 204,206 ----
  
! @ @<Handle {\caps set idle}@>=
  UEINTX &= ~(1 << RXSTPI);
***************
*** 206,207 ****
--- 210,214 ----
  
+ When previous packet was sent, TXINI becomes 1. A new packet may be sent only
+ after TXINI becomes 1. With TXINI the logic is the same as with UDRE.
+ 
  Here we also handle one case when data (serial number) needs to be transmitted from memory,
***************
*** 239,241 ****
        }
!       UEDATX = pgm_read_byte_near((unsigned int) buf++);
        size--;
--- 246,248 ----
        }
!       UEDATX = pgm_read_byte(buf++);
        size--;
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
!       while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent, then prepare
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
!       while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent */
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
*** 583,588 ****
  struct (aside from possibly adding some padding at the end) but gcc lets you initialize it anyway.
! So, |sizeof| on the variable counts only first two elements.
! So, we use |pgm_read_byte|\footnote*{In |@<Handle {\caps get descriptor string} (manufacturer)@>|
! and |@<Handle {\caps get descriptor string} (product)@>|.} to read the size of the variable at
! execution time.
  TODO: put here explanation from \.{https://stackoverflow.com/questions/51470592/}
--- 565,571 ----
  struct (aside from possibly adding some padding at the end) but gcc lets you initialize it anyway.
! |sizeof| on the variable counts only first two elements.
! So, we read the size of the variable at
! execution time in |@<Handle {\caps get descriptor string} (manufacturer)@>|
! and |@<Handle {\caps get descriptor string} (product)@>| by using |pgm_read_byte|.
! 
  TODO: put here explanation from \.{https://stackoverflow.com/questions/51470592/}
***************
*** 601,603 ****
  
! #define STR_DESC(str) { 1 + 1 + sizeof str - 2, 0x03, str }
  
--- 584,586 ----
  
! #define STR_DESC(str) @,@,@,@, {@, 1 + 1 + sizeof str - 2, 0x03, str @t\hskip1pt@>}
  
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
