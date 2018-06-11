/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the possible external configuration of the USB
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _CONF_USB_H_
#define _CONF_USB_H_

#include "modules/usb/usb_commun.h"
#include "modules/usb/usb_commun_cdc.h"


//! @defgroup usb_general_conf USB application configuration
//!
//! @{


   // _________________ USB MODE CONFIGURATION ____________________________
   //
   //! @defgroup USB_op_mode USB operating modes configuration
   //! defines to enable device or host usb operating modes
   //! supported by the application
   //! @{

      //! @brief ENABLE to activate the device software library support
      //!
      //! Possible values ENABLE or DISABLE
      #define USB_DEVICE_FEATURE          ENABLED

   //! @}

#define NB_ENDPOINTS 4 /* number of endpoints in the application including control endpoint */
#define TX_EP                0x01
#define RX_EP                0x02
#define INT_EP              0x03

#define Usb_unicode(a)         ((U16)(a))

#endif // _CONF_USB_H_
