/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file contains the function declarations
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _USB_TASK_H_
#define _USB_TASK_H_

//! @defgroup usb_task USB task entry point
//! @{

//_____ I N C L U D E S ____________________________________________________


//_____ M A C R O S ________________________________________________________

      //! @defgroup usb_software_evts USB software Events Management
      //! Macros to manage USB events detected under interrupt
      //! @{
#define Usb_send_event(x)               (g_usb_event |= (1<<x))
#define Usb_ack_event(x)                (g_usb_event &= ~(1<<x))
#define Usb_clear_all_event()           (g_usb_event = 0)
#define Is_usb_event(x)                 ((g_usb_event & (1<<x)) ? TRUE : FALSE)
#define Is_not_usb_event(x)             ((g_usb_event & (1<<x)) ? FALSE: TRUE)
#define Is_host_emergency_exit()        (Is_usb_event(EVT_HOST_DISCONNECTION) || Is_usb_event(EVT_USB_DEVICE_FUNCTION))
#define Is_usb_device()                 (g_usb_mode==USB_MODE_DEVICE ? TRUE : FALSE)
#define Is_usb_host()                   (g_usb_mode==USB_MODE_HOST   ? TRUE : FALSE)

#define EVT_USB_POWERED               1         // USB plugged
#define EVT_USB_UNPOWERED             2         // USB un-plugged
#define EVT_USB_DEVICE_FUNCTION       3         // USB in device
#define EVT_USB_HOST_FUNCTION         4         // USB in host
#define EVT_USB_RESUME                7         // USB resume
#define EVT_USB_RESET                 8         // USB reset
#define EVT_HOST_SOF                  9         // Host start of frame sent
#define EVT_HOST_HWUP                 10        // Host wakeup detected
#define EVT_HOST_DISCONNECTION        11        // The target device is disconnected
      //! @}


#define USB_MODE_UNDEFINED            0x00
#define USB_MODE_HOST                 0x01
#define USB_MODE_DEVICE               0x02

//_____ D E C L A R A T I O N S ____________________________________________

extern volatile U16 g_usb_event;
extern U8 g_usb_mode;

/**
 * @brief This function initializes the USB proces.
 *
 *  This function enables the USB controller and init the USB interrupts.
 *  The aim is to allow the USB connection detection in order to send
 *  the appropriate USB event to the operating mode manager.
 *  Depending on the mode supported (HOST/DEVICE/DUAL_ROLE) the function
 *  calls the corespong usb mode initialization function
 *
 *  @param none
 *
 *  @return none
 */
void usb_task_init     (void);

/**
 *  @brief Entry point of the USB mamnagement
 *
 *  Depending on the mode supported (HOST/DEVICE/DUAL_ROLE) the function
 *  calls the corespong usb management function
 *
 *  @param none
 *
 *  @return none
*/
void usb_task          (void);

//! @}

#endif /* _USB_TASK_H_ */

