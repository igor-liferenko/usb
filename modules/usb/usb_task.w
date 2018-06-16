@ @c
#include "config.h"
#include "conf_usb.h"
#include "usb_task.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/pll/pll_drv.h"
#include "modules/usb/device_chap9/usb_device_task.h"

//!


// general USB interrupt subroutine. This subroutine is used
// to detect asynchronous USB events.
ISR(USB_GEN_vect)
{
  // - USB bus reset detection
  if (Is_usb_reset()&& Is_reset_interrupt_enabled()) {
    UDINT = ~(1 << EORSTI);

    UECONX |= 1 << EPEN;
    UECFG1X |= (SIZE_32 << 4) | (ONE_BANK << 2); /* it seems configuration is reset
      (datasheet says that it isn't) because enumeration fails without reconfiguring
      after reset */
  }
}
