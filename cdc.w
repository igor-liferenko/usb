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
