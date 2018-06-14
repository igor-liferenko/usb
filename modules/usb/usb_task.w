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

// number of the USB configuration used by the USB device
// when its value is different from zero, it means the device mode is enumerated
extern U8    usb_configuration_nb;

// general USB interrupt subroutine. This subroutine is used
// to detect asynchronous USB events.
ISR(USB_GEN_vect)
{
  // - USB bus reset detection
   if (Is_usb_reset()&& Is_reset_interrupt_enabled())
   {
      Usb_ack_reset();
      usb_init_device();
      Usb_send_event(EVT_USB_RESET);
   }
}
