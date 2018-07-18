@x
@d EP2 2
@y
@z

@x
@ @<Global \null variables@>=
volatile uint8_t a[8];
@y
@z

@x
  else if (UEINT == (1 << EP1)) {
    for (int i = 0; i < 8; i++)
      UEDATX = a[i];
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);

    UENUM = EP2;
  }
@y
  else if (UEINT == (1 << EP1)) {
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0x04;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);
    while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent, then prepare
      new packet to be sent when following IN request arrives (for key release) */
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);
  }
@z

@x
  else if (UEINT == (1 << EP2)) {
    UEINTX &= ~(1 << RXOUTI);
    for (int i = 0; i < 8; i++)
      a[i] = UEDATX;
    UEINTX &= ~(1 << FIFOCON);

    UENUM = EP1;
    UEIENX = 1 << TXINE; /* trigger interrupt when current bank is free and can be filled */
  }
@y
@z

@x
UENUM = EP2;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1) + (1 << EPTYPE0) | (0 << EPDIR); /* interrupt\footnote\ddag
{Must correspond to OUT endpoint description in |@<Initialize element 5...@>|.}, OUT */
UECFG1X = (0 << EPBK0) | (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 8 bytes\footnote
{\ddag\ddag}{Must correspond to OUT endpoint description in |hid_report_descriptor|.} */
while (!(UESTA0X & (1 << CFGOK))) ;
@y
@z
  
@x
  UENUM = EP2;
@y
  UENUM = EP1;
@z

@x
  send_descriptor(&(hid_report_descriptor[0]), wLength);

  UENUM = EP2;
  UEIENX = 1 << RXOUTE; /* trigger interrupt when OUT packet arrives */
@y
  send_descriptor(&(hid_report_descriptor[0]), wLength);

  UENUM = EP1;
  UEIENX = 1 << TXINE; /* trigger interrupt when current bank is free and can be filled */
@z

@x
case 0x03:
  send_descriptor(&(sn_desc[0]), sizeof sn_desc);
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'N';
  break;
@y
@z

@x
$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=hid-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$
@y
$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=kbd-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$
@z

@x
   S_endpoint_descriptor      ep2;
@y
@z

@x
  @<Initialize element 4...@>, @/
@t\2@> @<Initialize element 5...@> @/
@y
@t\2@> @<Initialize element 4...@> @/
@z

@x
  0x02, /* two endpoints are used */
@y
  0x01, /* one endpoint is used */
@z

@x
@ @d OUT (0 << 7)

@<Initialize element 5 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_endpoint_descriptor), @/
  0x05, /* endpoint */
  OUT | 2, /* this corresponds to `2' in `ep2' on picture */
  0x03, /* transfers via interrupts\footnote\ddag{Must correspond to
    |UECFG0X| of |EP2|.} */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}
@y
@z

@x
@*1 HID report descriptor.

Line 1: Device class with common characteristics. First byte is either |0x05|
or |0x06|. Two last bits of first byte show number of remaining bytes in this field.
Number |0x06| in binary is 00000110. Two last bits (10) is decimal 2. So, after
first byte follow two bytes -- |0x00| and |0xFF|. In this case the device
does not belong to any class and its purpose is vendor defined.

Line 2: Device or function subclass. First byte is the field identifier. Second byte
is the device or function identifier. In this case these identifiers are not used (lines 2, 4, 10).

Line 3: Begin group of elements of one type. First byte is the field identifier.
Secand byte is type identifier. In this case it is an application group (|0x01|).

Line 5: Minimum value in each received byte, in logical units.
The value is set in second byte.

Line 6: Maximum value in each received byte, in logical units.
The value is set in second byte. Two last bits of first byte show number of remaining bytes
in this field. 
Number |0x26| in binary is 00011010. Two last bits (10) is decimal 2. So, after
first byte follow two bytes -- |0xFF| and |0x00|. FIXME: what for is second of them?

Line 7: Data unit size in bits.

Line 8: Number of data units in report.

Line 9: Report type of all preceding lines from the beginning of group is IN.
In first byte |0x81| (binary 10000001) the first four bits signify report type (IN).
Two last bits show number of remaining bytes in this field. In this case it is one
byte (|0x02|). This byte says the characteristics and layout of data in
report. Number |0x02| means that report data can change (Data),
is represented as 8 separate 8-bit elements (Variable), and their values are taken
relative to zero (Absolute).

Lines 11--14 are anologous to lines 5--8. But now they refer to OUT-report.

Line 15: The same as line 9. The difference is in the first byte (|0x91|),
first four bits of which are 1001, which signifies OUT report type.

Line 16: End group of elements of one type.

@<Global variables ...@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x06, 0x00, 0xFF, /* {\bf1} Usage Page (Vendordefined) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf2} Usage (UsageID - 1) */
  0xA1, 0x01, @t\hskip21pt@> /* {\bf3} Collection (Application) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf4} Usage (UsageID - 2) */
  0x15, 0x00, @t\hskip21pt@> /* {\bf5} Logical Minimum (0) */
  0x26, 0xFF, 0x00, /* {\bf6} Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* {\bf7} Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* {\bf8} Report Count (8) */
  0x81, 0x02, @t\hskip21pt@> /* {\bf9} IN report (Data, Variable, Absolute) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf10} Usage (UsageID - 3) */
  0x15, 0x00, @t\hskip21pt@> /* {\bf11} Logical Minimum (0) */
  0x26, 0xFF,0x00, /* {\bf12} Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* {\bf13} Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* {\bf14} Report Count (8) */
  0x91, 0x02, @t\hskip21pt@> /* {\bf15} OUT report (Data, Variable, Absolute) */
@t\2@> 0xC0 @t\hskip46pt@> /* {\bf16} End Collection */
};
@y
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

{\bf Note:} A keyboard might contain a pointing device in addition to its keys. In that
case, each input report will need to be prefixed with a report ID.

% https://docs.mbed.com/docs/ble-hid/en/latest/api/md_doc_HID.html
% http://microsin.net/programming/avr-working-with-usb/%
%   avr271-usb-keyboard-demonstration.html

@<Global variables ...@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
TODO: do the following via hid descriptor tool and export to C code
  HID_USAGE_PAGE @,@, (GENERIC_DESKTOP), @/
  HID_USAGE @,@, (KEYBOARD), @/
  HID_COLLECTION @,@, (APPLICATION), @t\1@> @/
    HID_USAGE_PAGE @,@, (KEYBOARD), @/
    HID_USAGE_MINIMUM @,@, (1, 0xe0), /* Left Control */
    HID_USAGE_MAXIMUM @,@, (1, 0xe7), /* Right GUI */
    HID_LOGICAL_MINIMUM @,@, (1, 0), @/
    HID_LOGICAL_MAXIMUM @,@, (1, 1), @/
    HID_REPORT_SIZE @,@, (1), @/
    HID_REPORT_COUNT @,@, (8), @/
    HID_INPUT @,@, (DATA, VARIABLE, ABSOLUTE), @/
    HID_REPORT_COUNT @,@, (1), @/
    HID_REPORT_SIZE @,@, (8), @/
    HID_INPUT @,@, (CONSTANT, VARIABLE, ABSOLUTE), @/
    HID_REPORT_COUNT @,@, (6), @/
    HID_REPORT_SIZE @,@, (8), @/
    HID_USAGE_MINIMUM @,@, (1, 0), @/
    HID_USAGE_MAXIMUM @,@, (1, 101), @/
    HID_LOGICAL_MINIMUM @,@, (1, 0), @/
    HID_LOGICAL_MAXIMUM @,@, (1, 101), @/
  @t\2@> HID_INPUT @,@, (DATA, ARRAY, ABSOLUTE), @/
@t\2@> HID_END_COLLECTION @,@,() @/
};
@z

@x
@*1 Serial number descriptor.

@<Global \null variables@>=
const uint8_t sn_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x0A, /* size */
  0x03, /* type (string) */
@t\2@> '0', 0, '0', 0, '0', 0, '0', 0 /* set only what is in quotes */
};
@y
@z
