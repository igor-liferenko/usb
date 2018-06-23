@ @c
/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file manages the CDC task.
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

//_____  I N C L U D E S ___________________________________________________

#include "config.h"
#include "conf_usb.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "modules/usb/ch9/usb_standard_request.h"
#include "usb_specific_request.h"
#include "uart_usb_lib.h"

//_____ M A C R O S ________________________________________________________



//_____ D E F I N I T I O N S ______________________________________________



//_____ D E C L A R A T I O N S ____________________________________________


extern U8    rx_counter;
extern U8    tx_counter;

S_line_coding line_coding;
S_line_status line_status;      // for detection of serial state input lines

volatile U8 rs2usb[10];


//! @brief Entry point of the uart cdc management
//!
//! This function links the uart and the USB bus.
//!
//! @param none
//!
//! @return none
void cdc_task(void)
{
  if (Is_device_enumerated() && line_status.DTR) { //Enumeration processs OK and COM port openned ?
    if (UCSR1A & (1<<UDRE1)) { /* can we send? */
      if (uart_usb_test_hit()) { // Something received from the USB ?
        while (rx_counter) {
          while(!(UCSR1A & (1<<UDRE1))) ;
          (void) 0; /* always set Busy flag before sending (not implemented) */
          @<Read one byte from the USB bus...@>@;
        }
      }
    }
  }
}

@ If one byte is present in the USB fifo, this byte is returned. If no data
is present in the USB fifo, wait for USB data.

@<Read one byte from the USB bus and send it to UART@>=
Usb_select_endpoint(RX_EP);
if (!rx_counter) while (!uart_usb_test_hit());
UDR1 = Usb_read_byte();
rx_counter--;
if (!rx_counter) Usb_ack_receive_out();

@ @c
ISR(USART1_RX_vect)
{
   U8 i=0;
   U8 save_ep;
   
   if(Is_device_enumerated()) 
   {
      save_ep=Usb_get_selected_endpoint();   
      Usb_select_endpoint(TX_EP);

      do 
      {
         if(UCSR1A & (1<<RXC1)) { /* if a character was received */
            rs2usb[i]=UDR1;
            i++;
         }
      }while(Is_usb_write_enabled()==FALSE );
      @<Transmit RAM buffer content to USB@>@;
      Usb_select_endpoint(save_ep);
   }
}

@ This is mode efficient in term of USB bandwith transfer.
FIXME: handling of |buffer| is strange here - why use pointer to pointer?
@^FIXME@>

@<Transmit RAM...@>=
   U8 *buffer = (U8*)&rs2usb;
   U8 nb_data = i;
   U8 zlp;
   // Compute if zlp required
   if(nb_data%TX_EP_SIZE)
   { zlp=FALSE;}
   else { zlp=TRUE; }

   Usb_select_endpoint(TX_EP);
   while (nb_data)
   {
      while ((UEINTX & (1 << RWAL)) == FALSE) ; // Wait Endpoint ready
      while ((UEINTX & (1 << RWAL)) && nb_data) {
         Usb_write_byte(*buffer);
         buffer++;
         nb_data--;
      }
      UEINTX &= ~(1 << TXINI), Usb_ack_fifocon();
   }
   if (zlp) {
      while ((UEINTX & (1 << RWAL)) == FALSE) ; // Wait Endpoint ready
      UEINTX &= ~(1 << TXINI), Usb_ack_fifocon();
   }
