@ @c
#include "config.h"
#include "conf_usb.h"
#include "usb_task.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/pll/pll_drv.h"
#include "modules/usb/device_chap9/usb_device_task.h"

ISR(USB_GEN_vect)
{
  // - USB bus reset detection
  if ((UDINT & (1<<EORSTI)) && (UDIEN & (1<<EORSTE))) {
    UDINT = ~(1 << EORSTI);

    UECONX |= 1 << EPEN;
    UECFG1X |= 1 << 5; /* repeat configuration (???) */
  }
}
