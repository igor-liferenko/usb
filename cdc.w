TODO: do here based on demo/main.w

@ TODO: first make it work as it is now, and then make it as similar to |dev_desc| in
kbd.w as possible (except 5th byte, maybe VID PID bytes)
@^TODO@>

@c
code const S_device_descriptor dev_desc =
{
  sizeof(usb_dev_desc),
  0x01, @/
  0x0200, @/
  0x02, /* CDC */
  0x00, @/
  0x00, @/
  EP0_SIZE,
  0x03EB, /* VID */
  0x2018, /* PID */
  0x1000, @/
  0x00, @/
  0x00, @/
  0x00, @/
  1
};

@ To receive data on an OUT endpoint:

@c
#if 0
    UEINTX &= ~(1 << RXOUTI);
    <read UEDATX>
    UEINTX &= ~(1 << FIFOCON);
#endif

------------------
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
------------------
@ @<Handle {\caps get descriptor string} (serial)@>=
UEINTX &= ~(1 << RXSTPI);
send_descriptor(NULL, 1 + 1 + SN_LENGTH * 2); /* multiply because Unicode */
------------------
Here we also handle one case when data (serial number) needs to be transmitted from memory,
not from program.

@<Functions@>=
void send_descriptor(const void *buf, int size)
{
  @<Fill in serial number if |buf == NULL|@>@;
#if 1
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE)
        break;
      UEDATX = from_program ? pgm_read_byte(buf++) : *(uint8_t *) buf++;
--------------------------
@ @d MANUFACTURER 0x01
@d PRODUCT 0x02
@d SERIAL_NUMBER 0x03
@d NOT_USED 0x00

@<Global \null variables@>=
const S_device_descriptor dev_desc
----------------------------
@*1 Language descriptor.

This is necessary to transmit manufacturer, product and serial number.
------------------------------
@*1 Serial number descriptor.

This one is different in that its content cannot be prepared in compile time,
only in execution time. So, it cannot be stored in program memory.
Therefore, a special trick is used in |send_descriptor| (to avoid cluttering it with
arguments): we pass a null pointer if serial number is to be transmitted.
In |send_descriptor| |sn_desc| is filled in.

@d SN_LENGTH 20 /* length of device signature, multiplied by two (because each byte in hex) */

@<Global \null variables@>=
struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  int16_t wString[SN_LENGTH];
} sn_desc;

@ @<Fill in serial number if |buf == NULL|@>=
int from_program = 1;
if (buf == NULL) {
  from_program = 0;
  @<Get serial number@>@;
  buf = &sn_desc;
}

@ @d SN_START_ADDRESS 0x0E
@d hex(c) c<10 ? c+'0' : c-10+'A'

@<Get serial number@>=
sn_desc.bLength = 1 + 1 + SN_LENGTH * 2; /* multiply because Unicode */
sn_desc.bDescriptorType = 0x03;
uint8_t addr = SN_START_ADDRESS;
for (uint8_t i = 0; i < SN_LENGTH; i++) {
  uint8_t c = boot_signature_byte_get(addr);
  if (i & 1) { /* we divide each byte of signature into halves, each of
                  which is represented by a hex number */
    c >>= 4;
    addr++;
  }
  else c &= 0x0F;
  sn_desc.wString[i] = hex(c);
}
---------------------------------

@ initialization of out endpoint structure
@d OUT (0 << 7)
@c
/*  \.{OUT \char'174\ 2} */

@i control-endpoint-management.w

@i IN-endpoint-management.w

@* OUT endpoint management.

There is only one stage (data). It corresponds to the following transaction(s):
\bigskip
$$\hbox to6cm{\vbox to0.94cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=1700}}\hfil}$$
$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to16cm{\vbox to4.29cm{\vfil\special{psfile=OUT.eps
  clip llx=0 lly=0 urx=1348 ury=362 rwi=4535}}\hfil}$$
