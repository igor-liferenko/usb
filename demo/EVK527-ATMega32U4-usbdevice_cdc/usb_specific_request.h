/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief Specific enumeration process requests header file
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _USB_SPECIFIC_REQUEST_H_
#define _USB_SPECIFIC_REQUEST_H_

/*_____ I N C L U D E S ____________________________________________________*/

#include "config.h"

/*_____ M A C R O S ________________________________________________________*/

extern  code const S_usb_device_descriptor usb_dev_desc;
extern  code const S_usb_user_configuration_descriptor usb_conf_desc;
extern  code const S_usb_manufacturer_string_descriptor usb_user_manufacturer_string_descriptor;
extern  code const S_usb_product_string_descriptor usb_user_product_string_descriptor;
extern  code const S_usb_serial_number usb_user_serial_number;
extern  code const S_usb_language_id usb_user_language_id;



/*_____ D E F I N I T I O N ________________________________________________*/
Bool  usb_user_read_request(U8, U8);
Bool  usb_user_get_descriptor(U8 , U8);
void  usb_user_endpoint_init(U8);
void  cdc_get_line_coding();
void  cdc_set_line_coding();
void  cdc_set_control_line_state(U16);   
void  cdc_send_break(U16);
Bool  cdc_update_serial_state();   

// ____ T Y P E  D E F I N I T I O N _______________________________________

typedef struct
{
   U32 dwDTERate;
   U8 bCharFormat;
   U8 bParityType;
   U8 bDataBits;
}S_line_coding;

// type for set control line state message
// cdc spec 1.1 chapter 6.2.14
typedef union
{
   U8 all;
   struct {
      U8 DTR:1;
      U8 RTS:1;
      U8 unused:6;
   };
}S_line_status;

// type for hardware handshake support 
// cdc spec 1.1 chapter 6.3.5
typedef union
{
   U16 all;
   struct {
      U16 bDCD:1;
      U16 bDSR:1;
      U16 bBreak:1;
      U16 bRing:1;
      U16 bFraming:1;
      U16 bParity:1;
      U16 bOverRun:1;
      U16 reserved:9;
   };
}S_serial_state;
   
      
   
   
#endif

