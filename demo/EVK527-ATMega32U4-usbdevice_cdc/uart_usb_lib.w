@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief @brief This file controls the UART USB functions.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

/*_____ I N C L U D E S ____________________________________________________*/

#include "config.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"

#include "uart_usb_lib.h"

/*_____ M A C R O S ________________________________________________________*/

/*_____ D E F I N I T I O N ________________________________________________*/


Uchar rx_counter;

/*_____ D E C L A R A T I O N ______________________________________________*/

/** 
  * @brief Initializes the uart_usb library
  */
void uart_usb_init(void)
{
  rx_counter = 0;
}

/** 
  * @brief This function checks if a character has been received on the USB bus.
  * 
  * @return bit (true if a byte is ready to be read)
  */
bit uart_usb_test_hit(void)
{
  if (!rx_counter)
  {
    Usb_select_endpoint(RX_EP);
    if (Is_usb_receive_out())
    {
      rx_counter = Usb_byte_counter();
      if (!rx_counter)
      {
        Usb_ack_receive_out();
      }
    }
  }
  return (rx_counter!=0);
}



/** 
  * @brief This function checks if the USB emission buffer is ready to accept at
  * at least 1 byte
  * 
  * @return Boolean. TRUE if the firmware can write a new byte to transmit.
  */
bit uart_usb_tx_ready(void)
{
  if (!Is_usb_write_enabled())
  {
    return FALSE;
  }
  return TRUE;
}




/** 
  * @brief This function transmits a ram buffer content to the USB.
  * This function is mode efficient in term of USB bandwith transfer.
  * 
  * @param U8 *buffer : the pointer to the RAM buffer to be sent 
  * @param data_to_send : the number of data to be sent
  */
void uart_usb_send_buffer(U8 *buffer, U8 nb_data)
{
   U8 zlp;
   
   // Compute if zlp required
   if(nb_data%TX_EP_SIZE) 
   { zlp=FALSE;} 
   else { zlp=TRUE; }
   
   Usb_select_endpoint(TX_EP);
   while (nb_data)
   {
      while(Is_usb_write_enabled()==FALSE); // Wait Endpoint ready
      while(Is_usb_write_enabled() && nb_data)
      {
         Usb_write_byte(*buffer);
         buffer++;
         nb_data--;
   }
      Usb_ack_in_ready();
   }
   if(zlp)
   {
      while(Is_usb_write_enabled()==FALSE); // Wait Endpoint ready 
      Usb_ack_in_ready();
}
}
