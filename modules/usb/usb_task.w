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
    UDINT = ~(1<<EORSTI);

    UENUM = EP_CONTROL; /* FIXME: check with green led if it is necessary */
    UECONX |= 1 << EPEN; /* FIXME: check with green led if it is already enabled */

    UECFG0X = (TYPE_CONTROL << 6) | DIRECTION_OUT; /* according to documentation, it must remain */
    UECFG1X = (1 << ALLOC) | (SIZE_32 << 4) | (ONE_BANK << 2); /* configured - ????????????? */
  }
}
