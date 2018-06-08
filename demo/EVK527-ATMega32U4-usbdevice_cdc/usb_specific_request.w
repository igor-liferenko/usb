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
#include "modules/usb/device_chap9/usb_standard_request.h"
#include "usb_specific_request.h"
#include "lib_mcu/uart/uart_lib.h"

//_____ M A C R O S ________________________________________________________

//_____ D E F I N I T I O N ________________________________________________

//_____ P R I V A T E   D E C L A R A T I O N ______________________________

extern PGM_VOID_P pbuffer;
extern U8   data_to_transfer;
extern S_line_coding   line_coding;
extern S_line_status line_status;


// We buffer the old state as it is wize only to send this interrupt message if
// sstate has changed.
extern S_serial_state serial_state;         // actual state
static S_serial_state serial_state_saved;   // buffered previously sent state
volatile U8 usb_request_break_generation=FALSE;


//_____ D E C L A R A T I O N ______________________________________________

//! @breif This function checks the specific request and if known then processes it
//!
//! @param type      corresponding at bmRequestType (see USB specification)
//! @param request   corresponding at bRequest (see USB specification)
//!
//! @return TRUE,  when the request is processed
//! @return FALSE, if the request is'nt know (STALL handshake is managed by the main standard request function).
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
   
         case SETUP_CDC_SEND_BREAK:
         cdc_send_break(wValue);             // wValue contains break lenght
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
{
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
   UBRR1 = (U16)(((U32)FOSC*1000L)/((U32)line_coding.dwDTERate*16)-1);
}


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

//! cdc_update_serial_state.
//!
//! @brief This function checks if serial state has changed and updates host with that information.
//!
//! @todo Return TRUE only if update was accepted by host, to detect need for resending
//!
//! @param none
//!
//! @return TRUE if updated state was sent otherwise FALSE
//!
//! @comment upr: Added for hardware handshake support according cdc spec 1.1 chapter 6.3.5
//!
Bool cdc_update_serial_state()
{
   if( serial_state_saved.all != serial_state.all)
   {
      serial_state_saved.all = serial_state.all;
      
      Usb_select_endpoint(INT_EP);
      if (Is_usb_write_enabled())
      {
         Usb_write_byte(USB_SETUP_GET_CLASS_INTER);   // bmRequestType
         Usb_write_byte(SETUP_CDC_BN_SERIAL_STATE);   // bNotification
         
         Usb_write_byte(0x00);   // wValue (zero)
         Usb_write_byte(0x00);
         
         Usb_write_byte(0x00);   // wIndex (Interface)
         Usb_write_byte(0x00);
         
         Usb_write_byte(0x02);   // wLength (data count = 2)
         Usb_write_byte(0x00);
         
         Usb_write_byte(LSB(serial_state.all));   // data 0: LSB first of serial state
         Usb_write_byte(MSB(serial_state.all));   // data 1: MSB follows
         Usb_ack_in_ready();
      }
      return TRUE;
   }
   return FALSE;
}

//! cdc_send_break.
//!
//! @brief This function manages the SEND_BREAK CDC request.
//!
//! @todo Manages here hardware flow control...
//!
//! @param break lenght
//!
//! @return none
//!
void cdc_send_break(U16 break_duration)
{
     Usb_ack_receive_setup();
   Usb_send_control_in();
   usb_request_break_generation=TRUE;
   
     while(!(Is_usb_read_control_enabled()));

}


