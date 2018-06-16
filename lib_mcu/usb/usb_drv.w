@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the USB driver routines.
//!
//!  This file contains the USB driver routines.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

//_____ I N C L U D E S ____________________________________________________

#include "config.h"
#include "conf_usb.h"
#include "usb_drv.h"

//_____ M A C R O S ________________________________________________________

//_____ D E C L A R A T I O N ______________________________________________



//! usb_configure_endpoint.
//!
//!  This function configures an endpoint with the selected type.
//!
//!
//! @param config0
//! @param config1
//!
//! @return Is_endpoint_configured.
//!
U8 usb_config_ep(U8 config0, U8 config1)
{
    Usb_enable_endpoint();
    UECFG0X = config0;
    UECFG1X = (UECFG1X & (1<<ALLOC)) | config1;
    Usb_allocate_memory();
    return (Is_endpoint_configured());
}

//! usb_select_endpoint_interrupt.
//!
//! This function select the endpoint where an event occurs and returns the
//! number of this endpoint. If no event occurs on the endpoints, this
//! function returns 0.
//!
//!
//! @param none
//!
//! @return endpoint number.
//!
U8 usb_select_enpoint_interrupt(void)
{
U8 interrupt_flags;
U8 ep_num;

   ep_num = 0;
   interrupt_flags = Usb_interrupt_flags();

   while(ep_num < MAX_EP_NB)
   {
      if (interrupt_flags & 1)
      {
         return (ep_num);
      }
      else
      {
         ep_num++;
         interrupt_flags = interrupt_flags >> 1;
      }
   }
   return 0;
}
