@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief user call-back functions
//!
//!  This file contains the user call-back functions corresponding to the
//!  application:
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
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "modules/usb/ch9/usb_standard_request.h"
#include "usb_specific_request.h"

//_____ M A C R O S ________________________________________________________

//_____ D E F I N I T I O N ________________________________________________

//_____ P R I V A T E   D E C L A R A T I O N ______________________________

extern PGM_VOID_P pbuffer;
extern U8   data_to_transfer;
extern S_line_coding   line_coding;
extern S_line_status line_status;


//_____ D E C L A R A T I O N ______________________________________________

//! @breif This function checks the specific request and if known then processes it
//!
//! @param type      corresponding at bmRequestType (see USB specification)
//! @param request   corresponding at bRequest (see USB specification)
//!
//! @return TRUE,  when the request is processed
//! @return FALSE, if the request is'nt know (STALL handshake is managed by the main
// standard request function).
//!
Bool usb_user_read_request(U8 type, U8 request)
{
   U16 wValue;

   LSB(wValue) = Usb_read_byte();
   MSB(wValue) = Usb_read_byte();

   if( USB_SETUP_SET_CLASS_INTER == type )
   {
      switch( request )
      {
         case SETUP_CDC_SET_LINE_CODING:
         cdc_set_line_coding();
         return TRUE;
         break;
   
         case SETUP_CDC_SET_CONTROL_LINE_STATE:
         cdc_set_control_line_state(wValue); // according cdc spec 1.1 chapter 6.2.14
         return TRUE;
         break;
      }
   }
   if( USB_SETUP_GET_CLASS_INTER == type )
   {
      switch( request )
      {
         case SETUP_CDC_GET_LINE_CODING:
         cdc_get_line_coding();
         return TRUE;
         break;
      }
   }
   PORTD |= 1 << PD5; /* indicate error */
   return FALSE;  // No supported request
}


//! This function fills the global descriptor
//!
//! @param type      corresponding at MSB of wValue (see USB specification)
//! @param string    corresponding at LSB of wValue (see USB specification)
//!
//! @return FALSE, if the global descriptor no filled
//!
Bool usb_user_get_descriptor(U8 type, U8 string)
{ 
   return FALSE;
}


//! @brief This function configures the endpoints
//!
//! @param conf_nb configuration number choosed by USB host
//!
void usb_user_endpoint_init(U8 conf_nb)
{
  usb_configure_endpoint(INT_EP,      \
                         TYPE_INTERRUPT,     \
                         DIRECTION_IN,  \
                         SIZE_32,       \
                         ONE_BANK,     \
                         NYET_ENABLED);

  usb_configure_endpoint(TX_EP,      \
                         TYPE_BULK,  \
                         DIRECTION_IN,  \
                         SIZE_32,     \
                         ONE_BANK,     \
                         NYET_ENABLED);

  usb_configure_endpoint(RX_EP,      \
                         TYPE_BULK,     \
                         DIRECTION_OUT,  \
                         SIZE_32,       \
                         ONE_BANK,     \
                         NYET_ENABLED);

  Usb_reset_endpoint(INT_EP);
  Usb_reset_endpoint(TX_EP);
  Usb_reset_endpoint(RX_EP);


}

//! cdc_get_line_coding.
//!
//! @brief This function manages reception of line coding parameters (baudrate...).
//!
//! @param none
//!
//! @return none
//!
void cdc_get_line_coding(void)
{
     Usb_ack_receive_setup();
     Usb_write_byte(LSB0(line_coding.dwDTERate));
     Usb_write_byte(LSB1(line_coding.dwDTERate));
     Usb_write_byte(LSB2(line_coding.dwDTERate));
     Usb_write_byte(LSB3(line_coding.dwDTERate));
     Usb_write_byte(line_coding.bCharFormat);
     Usb_write_byte(line_coding.bParityType);
     Usb_write_byte(line_coding.bDataBits);

     Usb_send_control_in();
     while(!(Is_usb_read_control_enabled()));
     //Usb_clear_tx_complete();

   while(!Is_usb_receive_out());
   Usb_ack_receive_out();
}


//! cdc_set_line_coding.
//!
//! @brief This function manages reception of line coding parameters (baudrate...).
//!
//! @param none
//!
//! @return none
//!
void cdc_set_line_coding (void)
{ /* this is a stub */
   Usb_ack_receive_setup();
   while (!(Is_usb_receive_out()));
   LSB0(line_coding.dwDTERate) = Usb_read_byte();
   LSB1(line_coding.dwDTERate) = Usb_read_byte();
   LSB2(line_coding.dwDTERate) = Usb_read_byte();
   LSB3(line_coding.dwDTERate) = Usb_read_byte();
   line_coding.bCharFormat = Usb_read_byte();
   line_coding.bParityType = Usb_read_byte();
   line_coding.bDataBits = Usb_read_byte();
     Usb_ack_receive_out();

     Usb_send_control_in();                // send a ZLP for STATUS phase
     while(!(Is_usb_read_control_enabled()));
}

@ @c
//! cdc_set_control_line_state.
//!
//! @brief This function manages the SET_CONTROL_LINE_LINE_STATE CDC request.
//!
//! @todo Manages here hardware flow control...
//!
//! @param none
//!
//! @return none
//!
void cdc_set_control_line_state (U16 state)
{
     Usb_ack_receive_setup();
   Usb_send_control_in();
   line_status.all = state;
   
     while(!(Is_usb_read_control_enabled()));

}
