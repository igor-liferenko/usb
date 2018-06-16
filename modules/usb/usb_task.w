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
    UDINT   = ~(1<<EORSTI);

   Usb_select_endpoint(EP_CONTROL);
   if (!(UECONX & (1<<EPEN))) {
    UECONX |= (1 << EPEN); /* activate control endpoint */
/*FIXME: is the following needed? and see last command commented in |main| */
    UECFG0X = Usb_build_ep_config0(TYPE_CONTROL, DIRECTION_OUT, NYET_DISABLED);
    UECFG1X = (UECFG1X & (1<<ALLOC)) | Usb_build_ep_config1(SIZE_32, ONE_BANK);
    UECFG1X |=  (1<<ALLOC);


   }

   }
}
