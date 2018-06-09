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
#include "cdc_task.h"
#include "lib_mcu/usb/usb_drv.h"
#include "usb_descriptors.h"
#include "modules/usb/device_chap9/usb_standard_request.h"
#include "usb_specific_request.h"
#include "uart_usb_lib.h"
#include <stdio.h>


//_____ M A C R O S ________________________________________________________



//_____ D E F I N I T I O N S ______________________________________________



//_____ D E C L A R A T I O N S ____________________________________________


volatile U8 cpt_sof;
extern U8    rx_counter;
extern U8    tx_counter;
extern volatile U8 usb_request_break_generation;

S_line_coding line_coding;
S_line_status line_status;      // for detection of serial state input lines
S_serial_state serial_state;   // for serial state output lines

volatile U8 rs2usb[10];


//! @brief This function initializes the hardware ressources required for CDC demo.
//!
//!
//! @param none
//!
//! @return none
//!
//!/
void cdc_task_init(void)
{
   Usb_enable_sof_interrupt();
   fdevopen((int (*)(char, FILE*))(uart_usb_putchar),(int (*)(FILE*))uart_usb_getchar); //for printf redirection
}



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
          UDR1 = uart_usb_getchar();
        }
      }
    }

      if ( cpt_sof>=REPEAT_KEY_PRESSED)   //Debounce joystick events
      {
         printf("Hello from ATmega32U4 !\r\n");
         
         cdc_update_serial_state();
      }

      if(usb_request_break_generation==TRUE)
      {
         usb_request_break_generation=FALSE;
         DDRC |= 1 << PC7;
         PORTC |= 1<<PC7; /* see \.{start\_boot} in git lg and enable watchdog timer - see
           commit previous to the commit where this comment was added */
      }
  }
}

//! @brief sof_action
//!
//! This function increments the cpt_sof counter each times
//! the USB Start Of Frame interrupt subroutine is executed (1ms)
//! Usefull to manage time delays
//!
//! @warning Code:?? bytes (function code length)
//!
//! @param none
//!
//! @return none
void sof_action()
{
   cpt_sof++;
}


//! @brief Uart Receive interrupt subroutine
//!
//! @param none
//!
//! @return none
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
      uart_usb_send_buffer((U8*)&rs2usb,i);
      Usb_select_endpoint(save_ep);
   }
}
