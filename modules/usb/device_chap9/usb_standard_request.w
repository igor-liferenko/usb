@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief Process USB device enumeration requests.
//!
//!  This file contains the USB endpoint 0 management routines corresponding to
//!  the standard enumeration process (refer to chapter 9 of the USB
//!  specification.
//!  This file calls routines of the usb_specific_request.c file for non-standard
//!  request management.
//!  The enumeration parameters (descriptor tables) are contained in the
//!  usb_descriptors.c file.
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
#include "lib_mcu/pll/pll_drv.h"
#include "usb_specific_request.h"


//_____ M A C R O S ________________________________________________________


//_____ D E F I N I T I O N ________________________________________________

//_____ P R I V A T E   D E C L A R A T I O N ______________________________

static  void    usb_get_descriptor(   void);
static  void    usb_set_address(      void);
static  void    usb_set_configuration(void);
static  void    usb_clear_feature(    void);
static  void    usb_set_feature(      void);
static  void    usb_get_status(       void);
static  void    usb_get_interface (void);
static  void    usb_set_interface (void);


//_____ D E C L A R A T I O N ______________________________________________

static  bit  zlp;
static  U8   endpoint_status[MAX_EP_NB];
static  U8   device_status=DEVICE_STATUS;

        PGM_VOID_P pbuffer;
        U8   data_to_transfer;

        U16  wInterface;

static  U8   bmRequestType;
        U8   usb_configuration_nb;

//! usb_process_request.
//!
//! @brief This function reads the SETUP request sent to the default control endpoint
//! and calls the appropriate function. When exiting of the usb_read_request
//! function, the device is ready to manage the next request.
//!
//! @param none
//!
//! @return none
//! @note list of supported requests:
//! SETUP_GET_DESCRIPTOR
//! SETUP_GET_CONFIGURATION
//! SETUP_SET_ADDRESS
//! SETUP_SET_CONFIGURATION
//! SETUP_CLEAR_FEATURE
//! SETUP_SET_FEATURE
//! SETUP_GET_STATUS
//!
extern volatile int reset_done;
void usb_process_request(void)
{
   U8  bmRequest;

   Usb_ack_control_out();
   bmRequestType = Usb_read_byte();
   bmRequest     = Usb_read_byte();

   switch (bmRequest)
   {
    case SETUP_GET_DESCRIPTOR:
         if (USB_SETUP_GET_STAND_DEVICE == bmRequestType) {
           reset_done = 0;
           usb_get_descriptor();
         }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_GET_CONFIGURATION:
      if (USB_SETUP_GET_STAND_DEVICE == bmRequestType) {
        @<Process GET CONFIGURATION request@>@;
      }
      else {
        usb_user_read_request(bmRequestType, bmRequest);
      }
      break;

    case SETUP_SET_ADDRESS:
         if (USB_SETUP_SET_STAND_DEVICE == bmRequestType) { usb_set_address(); }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_SET_CONFIGURATION:
         if (USB_SETUP_SET_STAND_DEVICE == bmRequestType) { usb_set_configuration(); }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_CLEAR_FEATURE:
         if (USB_SETUP_SET_STAND_ENDPOINT >= bmRequestType) { usb_clear_feature(); }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_SET_FEATURE:
         if (USB_SETUP_SET_STAND_ENDPOINT >= bmRequestType) { usb_set_feature(); }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_GET_STATUS:
         if ((0x7F < bmRequestType) & (0x82 >= bmRequestType))
                                    { usb_get_status(); }
         else                       { usb_user_read_request(bmRequestType, bmRequest); }
         break;

    case SETUP_GET_INTERFACE:
          if (bmRequestType == USB_SETUP_GET_STAND_INTERFACE) { usb_get_interface(); }
          else { usb_user_read_request(bmRequestType, bmRequest); }
          break;


    case SETUP_SET_INTERFACE:
      if (bmRequestType == USB_SETUP_SET_STAND_INTERFACE) {usb_set_interface();}
      break;

    case SETUP_SET_DESCRIPTOR:
    case SETUP_SYNCH_FRAME:
    default: //!< un-supported request => call to user read request
         if(usb_user_read_request(bmRequestType, bmRequest) == FALSE)
         {
            Usb_enable_stall_handshake();
            Usb_ack_receive_setup();
            return;
         }
         break;
  }
}


//! usb_set_address.
//!
//! This function manages the SET ADDRESS request. When complete, the device
//! will filter the requests using the new address.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_set_address(void)
{
   U8 addr = Usb_read_byte();
   Usb_configure_address(addr);

   Usb_ack_receive_setup();

   Usb_send_control_in();                    //!< send a ZLP for STATUS phase
   while(!Is_usb_in_ready());                //!< waits for status phase done
                                             //!< before using the new address
   Usb_enable_address();
}


//! This function manages the SET CONFIGURATION request. If the selected
//! configuration is valid, this function call the usb_user_endpoint_init()
//! function that will configure the endpoints following the configuration
//! number.
//!
void usb_set_configuration( void )
{
U8 configuration_number;

   configuration_number = Usb_read_byte();

   if (configuration_number <= NB_CONFIGURATION)
   {
      Usb_ack_receive_setup();
      usb_configuration_nb = configuration_number;
   }
   else
   {
      //!< keep that order (set StallRq/clear RxSetup) or a
      //!< OUT request following the SETUP may be acknowledged
      Usb_enable_stall_handshake();
      Usb_ack_receive_setup();
      return;
   }

   Usb_send_control_in();                    //!< send a ZLP for STATUS phase

   usb_user_endpoint_init(usb_configuration_nb);  //!< endpoint configuration
}


//! This function manages the GET DESCRIPTOR request. The device descriptor,
//! the configuration descriptor and the device qualifier are supported. All
//! other descriptors must be supported by the usb_user_get_descriptor
//! function.
//! Only 1 configuration is supported.
//!
void usb_get_descriptor(void)
{
U16  wLength;
U8   descriptor_type ;
U8   string_type;
U8   nb_byte;

   zlp             = FALSE;         /* no zero length packet */
   string_type     = UEDATX;        /* read LSB of wValue    */
   descriptor_type = UEDATX;        /* read MSB of wValue    */

   switch (descriptor_type)
   {
    case DESCRIPTOR_DEVICE:
      data_to_transfer = sizeof (usb_dev_desc);
      pbuffer          = &usb_dev_desc.bLength;
      break;
    case DESCRIPTOR_CONFIGURATION:
      data_to_transfer = sizeof (usb_conf_desc);
      pbuffer          = &usb_conf_desc.cfg.bLength;
      break;
    default:
      if(usb_user_get_descriptor(descriptor_type, string_type) == FALSE) {
         UECONX |= 1 << STALLRQ;
         UEINTX &= ~(1 << RXSTPI);
         return;
      }
      break;
   }

   (void) UEDATX; /* don't care of wIndex */
   (void) UEDATX;
   ((U8*) &wLength)[0] = UEDATX; /* wLength LSB */
   ((U8*) &wLength)[1] = UEDATX; /* wLength MSB */
   UEINTX &= ~(1<<RXSTPI);

   if (data_to_transfer < wLength) {
      if ((data_to_transfer % EP_CONTROL_LENGTH) == 0) zlp = TRUE;
      else zlp = FALSE;                   //!< no need of zero length packet
   }
   else
     data_to_transfer = (U8) wLength;         /* send only requested number of data */

   UEINTX &= ~(1<<NAKOUTI);
   while ((data_to_transfer != 0) && !(UEINTX & (1 << NAKOUTI))) {
      while (!(UEINTX & (1 << TXINI))) {
        if (UEINTX & (1 << NAKOUTI))
          break;    // don't clear the flag now, it will be cleared after
      }

      nb_byte=0;
      while(data_to_transfer != 0) { /* Send data until necessary */
         if (nb_byte++==EP_CONTROL_LENGTH) /* Check endpoint 0 size */
            break;

         UEDATX = pgm_read_byte_near((unsigned int) pbuffer++);
         data_to_transfer--;
      }

      if (UEINTX & (1 << NAKOUTI))
        break;
      else
        UEINTX &= ~(1 << TXINI);
   }

   if ((zlp == TRUE) && !(UEINTX & (1 << NAKOUTI))) {
     while (!(UEINTX & (1 << TXINI))) ;
     UEINTX &= ~(1 << TXINI);
   }

   while (!(UEINTX & (1 << NAKOUTI))) ;
   UEINTX &= ~(1 << NAKOUTI);
   UEINTX &= ~(1 << RXOUTI);
}

@ This manages GET CONFIGURATION request.

@<Process GET CONFIGURATION request@>=
UEINTX &= ~(1 << RXSTPI); /* clear RXSTPI to determine if a new setup packet is received
  FIXME: do this in main.w in the end of "if" in |@<If setup packet is received...@>|? */

UEDATX = usb_configuration_nb;
UEINTX &= ~(1 << TXINI);
UEINTX &= ~(1 << FIFOCON);

while (!(UEINTX & (1 << RXOUTI))) ;
UEINTX &= ~(1 << RXOUTI);
UEINTX &= ~(1 << FIFOCON);

@ @c
//! usb_get_status.
//!
//! This function manages the GET STATUS request. The device, interface or
//! endpoint status is returned.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_get_status(void)
{
U8 wIndex;
U8 dummy;

   dummy    = Usb_read_byte();                 //!< dummy read
   dummy    = Usb_read_byte();                 //!< dummy read
   wIndex = Usb_read_byte();

   switch(bmRequestType)
   {
    case USB_SETUP_GET_STAND_DEVICE:    Usb_ack_receive_setup();
                                   Usb_write_byte(device_status);
                                   break;

    case USB_SETUP_GET_STAND_INTERFACE: Usb_ack_receive_setup();
                                   Usb_write_byte(INTERFACE_STATUS);
                                   break;

    case USB_SETUP_GET_STAND_ENDPOINT:  Usb_ack_receive_setup();
                                   wIndex = wIndex & MSK_EP_DIR;
                                   Usb_write_byte(endpoint_status[wIndex]);
                                   break;
    default:
                                   Usb_enable_stall_handshake();
                                   Usb_ack_receive_setup();
                                   return;
   }

   Usb_write_byte(0x00);
   Usb_send_control_in();

   while( !Is_usb_receive_out() );
   Usb_ack_receive_out();
}


//! usb_set_feature.
//!
//! This function manages the SET FEATURE request. The USB test modes are
//! supported by this function.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_set_feature(void)
{
U8 wValue;
U8 wIndex;
U8 dummy;

  switch (bmRequestType)
   {
    case USB_SETUP_SET_STAND_DEVICE:
      wValue = Usb_read_byte();
         Usb_enable_stall_handshake();
         Usb_ack_receive_setup();
      break;

  case USB_SETUP_SET_STAND_INTERFACE:
      //!< keep that order (set StallRq/clear RxSetup) or a
      //!< OUT request following the SETUP may be acknowledged
      Usb_enable_stall_handshake();
      Usb_ack_receive_setup();
    break;

  case USB_SETUP_SET_STAND_ENDPOINT:
      wValue = Usb_read_byte();
      dummy    = Usb_read_byte();                //!< dummy read

      if (wValue == FEATURE_ENDPOINT_HALT)
      {
         wIndex = (Usb_read_byte() & MSK_EP_DIR);

         if (wIndex == EP_CONTROL)
         {
            Usb_enable_stall_handshake();
            Usb_ack_receive_setup();
         }

         Usb_select_endpoint(wIndex);
         if(Is_usb_endpoint_enabled())
         {
            Usb_enable_stall_handshake();
            Usb_select_endpoint(EP_CONTROL);
            endpoint_status[wIndex] = 0x01;
            Usb_ack_receive_setup();
            Usb_send_control_in();
         }
         else
         {
            Usb_select_endpoint(EP_CONTROL);
            Usb_enable_stall_handshake();
            Usb_ack_receive_setup();
         }
      }
      else
      {
         Usb_enable_stall_handshake();
         Usb_ack_receive_setup();
      }
    break;

  default:
    Usb_enable_stall_handshake();
    Usb_ack_receive_setup();
    break;
   }
}


//! usb_clear_feature.
//!
//! This function manages the SET FEATURE request.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_clear_feature(void)
{
U8 wValue;
U8 wIndex;
U8 dummy;

   if (bmRequestType == USB_SETUP_SET_STAND_DEVICE)
   {
     wValue = Usb_read_byte();
      Usb_enable_stall_handshake();
      Usb_ack_receive_setup();
      return;
   }
   else if (bmRequestType == USB_SETUP_SET_STAND_INTERFACE)
   {
      //!< keep that order (set StallRq/clear RxSetup) or a
      //!< OUT request following the SETUP may be acknowledged
      Usb_enable_stall_handshake();
      Usb_ack_receive_setup();
      return;
   }
   else if (bmRequestType == USB_SETUP_SET_STAND_ENDPOINT)
   {
      wValue = Usb_read_byte();
      dummy  = Usb_read_byte();                //!< dummy read

      if (wValue == FEATURE_ENDPOINT_HALT)
      {
         wIndex = (Usb_read_byte() & MSK_EP_DIR);

         Usb_select_endpoint(wIndex);
         if(Is_usb_endpoint_enabled())
         {
            if(wIndex != EP_CONTROL)
            {
               Usb_disable_stall_handshake();
               Usb_reset_endpoint(wIndex);
               Usb_reset_data_toggle();
            }
            Usb_select_endpoint(EP_CONTROL);
            endpoint_status[wIndex] = 0x00;
            Usb_ack_receive_setup();
            Usb_send_control_in();
         }
         else
         {
            Usb_select_endpoint(EP_CONTROL);
            Usb_enable_stall_handshake();
            Usb_ack_receive_setup();
            return;
         }
      }
      else
      {
         Usb_enable_stall_handshake();
         Usb_ack_receive_setup();
         return;
      }
   }
}



//! usb_get_interface.
//!
//! TThis function manages the SETUP_GET_INTERFACE request.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_get_interface (void)
{
   Usb_ack_receive_setup();
   Usb_send_control_in();

   while( !Is_usb_receive_out() );
   Usb_ack_receive_out();
}

//! usb_set_interface.
//!
//! TThis function manages the SETUP_SET_INTERFACE request.
//!
//! @warning Code:xx bytes (function code length)
//!
//! @param none
//!
//! @return none
//!
void usb_set_interface (void)
{
  Usb_ack_receive_setup();
  Usb_send_control_in();                    //!< send a ZLP for STATUS phase
  while(!Is_usb_in_ready());
}
