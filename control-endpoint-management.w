@* Control endpoint management.
(WARNING: these images are incomplete --- they do not show possible handshake
phases)

Device driver sends a
packet to device's EP0. As the data is flowing out from the host, it will end
up in the EP0 buffer. Firmware will then at its leisure read this data. If it
wants to return data, the device cannot simply
write to the bus as the bus is controlled by the host.
Therefore it writes data to EP0 which sits in the buffer
until such time when the host sends a IN packet requesting the
data.\footnote*{This is where the prase ``USB controller has
to manage simultaneous write requests from firmware and host'' from \S22.12.2 of
datasheet becomes clear. (Remember, we use one and the same
endpoint to read {\it and\/} write control data.)}

@*1 Control read (by host). There are the folowing
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to7.83cm{\vbox to1.23472222222222cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=2220}}\hfil}$$

$$\hbox to11.28cm{\vbox to13.4055555555556cm{\vfil\special{psfile=control-read-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=3200}}\hfil}$$

$$\hbox to12.5cm{\vbox to4.22cm{\vfil\special{psfile=control-IN.eps
  clip llx=0 lly=0 urx=1206 ury=408 rwi=3543}}\hfil}$$

@ This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

@*1 Control write (by host). There are the following
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to7.83cm{\vbox to1.23472222222222cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=2220}}\hfil}$$

$$\hbox to11.28cm{\vbox to13.4055555555556cm{\vfil\special{psfile=control-write-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=3200}}\hfil}$$

$$\hbox to16cm{\vbox to4.39cm{\vfil\special{psfile=control-OUT.eps
  clip llx=0 lly=0 urx=1474 ury=405 rwi=4535}}\hfil}$$

Commentary to the drawing why ``controller will not necessarily send a NAK at the first IN token''
(see \S22.12.1 in datasheet): If TXINI is already cleared when IN packet arrives, NAKINI is not
set. This corresponds to case 1. If TXINI is not yet cleared when IN packet arrives, NAKINI
is set. This corresponds to case 2.

@ This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$
