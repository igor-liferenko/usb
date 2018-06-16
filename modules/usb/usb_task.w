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
//! Public : U16 g_usb_event
//! is used to store detected USB events
//! Its value is managed by the following macros (See usb_task.h file)
//! Usb_send_event(x)
//! Usb_ack_event(x)
//! Is_usb_event(x)
volatile U16 g_usb_event=0;

// general USB interrupt subroutine. This subroutine is used
// to detect asynchronous USB events.
ISR(USB_GEN_vect)
{
  // - USB bus reset detection
  if (Is_usb_reset()&& Is_reset_interrupt_enabled()) {
    UDINT   = ~(1<<EORSTI);

   Usb_select_endpoint(EP_CONTROL);
   if (!(UECONX & (1<<EPEN)))
     usb_configure_endpoint(EP_CONTROL,
                            TYPE_CONTROL,
                            DIRECTION_OUT,
                            SIZE_32,
                            ONE_BANK,
                            NYET_DISABLED);


     g_usb_event |= 1<<EVT_USB_RESET;
   }
}
